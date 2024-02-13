import mqtt
import uuid
import system.storage
import encoding.json

HOST ::= "192.168.137.36"     // Brockers ip address
PORT ::= 1883                 // Brockers port
TOPIC ::= "lifecycle/status"

main:
  task:: lifecycle

store-uuid:
  // Open esp system stroage bucket called "athena-bucket"
  // Bucket docs: https://libs.toit.io/system/storage/class-Bucket
  bucket := storage.Bucket.open --ram "athena-bucket"

  bucket.get "uuid" --if-absent=: bucket["uuid"] = (uuid.uuid5 "Athena" "$Time.now.local").to-string

  return bucket["uuid"]

lifecycle:
  // Get stored uuid
  client-id := store-uuid

  print "[Athena] INFO: retrived client-id: $client-id"

  // Initiate client for mqtt connection
  client := mqtt.Client --host=HOST --port=PORT

  // mqtt session settings for client acknowledge and authentication
  options := mqtt.SessionOptions
      --client-id=client-id
      --username="admin"
      --password="password"

  // Start client with session settings
  client.start --options=options

  print "[Athena] INFO: connected to broker"

  while true:
    payload := json.encode {
      "value": "NEW one with Athena container",
      "client-id": client-id,
      "now": Time.now.utc.to-iso8601-string
    }
    client.publish TOPIC payload
    sleep --ms=1_000
