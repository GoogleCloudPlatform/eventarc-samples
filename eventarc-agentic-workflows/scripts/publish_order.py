import argparse
import datetime
import json
import uuid
from google.cloud.eventarc_publishing_v1 import PublisherClient
from google.cloud.eventarc_publishing_v1.types import CloudEvent, PublishRequest
from google.protobuf import timestamp_pb2


def publish_order_event(bus_name, amount, items, address, note, env):
  """Publishes a simulated retail order to the Eventarc Advanced Message Bus."""

  # Initialize the Eventarc Publishing client
  client = PublisherClient()

  # Generate a random order ID
  order_id = f"ORD-{uuid.uuid4().hex[:6].upper()}"

  # 1. Construct the raw event data payload
  payload = {
      "order_id": order_id,
      "quantity": amount,
      "items": items,
      "shipping_address": address,
  }
  if note:
    payload["user_note"] = note

  # 2. Generate the current UTC time as a Protobuf Timestamp
  now = datetime.datetime.now(datetime.timezone.utc)
  proto_timestamp = timestamp_pb2.Timestamp()
  proto_timestamp.FromDatetime(now)

  # 3. Build the CloudEvent object
  event = CloudEvent(
      id=str(uuid.uuid4()),
      source="//commerce/frontend",
      spec_version="1.0",
      type_="order.created",
      text_data=json.dumps(payload),
      attributes={
          "time": CloudEvent.CloudEventAttributeValue(
              ce_timestamp=proto_timestamp
          ),
          "data_sensitivity": CloudEvent.CloudEventAttributeValue(
              ce_string="confidential"
          ),
          "datacontenttype": CloudEvent.CloudEventAttributeValue(
              ce_string="application/json"
          ),
          "amount": CloudEvent.CloudEventAttributeValue(ce_string=str(amount)),
          "env": CloudEvent.CloudEventAttributeValue(ce_string=env),
      },
  )

  # 4. Build the Publish Request
  request = PublishRequest(message_bus=bus_name, proto_message=event)

  print(f"\n[+] Preparing to publish Order: {order_id}")
  print(f"[+] Amount: ${amount:,.2f} | Items: {items}")
  if note:
    print(f"[+] User Note: {note}")

  print(f"\n[+] The entire event: {event}")

  try:
    # 5. Execute the publish call
    client.publish(request=request)
    print(f"\n[SUCCESS] Event {event.id} successfully published to the bus!")
  except Exception as e:
    print(f"\n[ERROR] Failed to publish event. Reason:\n{e}")


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
      description="Simulate a commerce frontend publishing events to Eventarc."
  )
  parser.add_argument(
      "--bus_name",
      type=str,
      required=True,
      help="The full resource name of the Eventarc message bus.",
  )
  parser.add_argument(
      "--amount",
      type=float,
      required=True,
      help="Total order amount to trigger the pipeline filter.",
  )
  parser.add_argument(
      "--items",
      type=str,
      default="1x Standard Item",
      help="The items in the order.",
  )
  parser.add_argument(
      "--address",
      type=str,
      default="",
      help="The address to ship the order to.",
  )
  parser.add_argument(
      "--note",
      type=str,
      default="",
      help="Optional user note (used for PII or Prompt Injections).",
  )
  parser.add_argument(
      "--env",
      type=str,
      default="demo",
      help="The environment for the event (e.g., demo, prod).",
  )

  args = parser.parse_args()

  publish_order_event(
      args.bus_name, args.amount, args.items, args.address, args.note, args.env
  )
