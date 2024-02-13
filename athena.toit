import mqtt
import uuid
import system.storage
import encoding.json

HOST ::= ""                   // Brokers ip address
PORT ::= 1883                 // Brokers port
TOPIC ::= "lifecycle/status"  // Publish topic

main:
  task:: lifecycle

store-uuid:
  // Open esp system stroage bucket called "athena-bucket"
  // Bucket docs: https://libs.toit.io/system/storage/class-Bucket
  bucket := storage.Bucket.open --ram "athena-bucket"

  // Check if an client uuid already exists in the Athena stroage bucket.
  // If not create a one and store it.
  bucket.get "uuid" --if-absent=: bucket["uuid"] = (uuid.uuid5 "Athena" "$Time.now.local").to-string

  // Return the stored uuid
  return bucket["uuid"]

lifecycle:
  // Get stored uuid
  client-id := store-uuid

  print "[Athena] INFO: retrived client-id: $client-id"

  // Initiate client for mqtt connection
  client := mqtt.Client --host=HOST --port=PORT

  // mqtt session settings for client acknowledge and authentication
  options := mqtt.SessionOptions
      --client-id = client-id
      --username  = ""   // Broker auth username
      --password  = ""   // Broker auth password

  // Start client with session settings
  client.start --options=options

  print "[Athena] INFO: connected to broker"

  // Lifecycle loop
  while true:
    // Create status lifecycle payload
    payload := json.encode {
      "value": "ESP with Toit firmware running Athena container",
      "client-id": client-id,
      "now": Time.now.utc.to-iso8601-string
    }

    // Publish the payload to the broker with specified topic
    client.publish TOPIC payload
    sleep --ms=1_000
