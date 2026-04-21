from datetime import datetime, timezone
import json
import os
from typing import Any, Optional, Union
import uuid
from google.cloud.eventarc_publishing_v1 import PublisherClient
from google.cloud.eventarc_publishing_v1.types import CloudEvent, PublishRequest


def publish_to_eventarc(
    bus: str,
    type: str,
    source: str,
    data: Optional[Any] = None,
    datacontenttype: str = None,
    subject: str = None,
    id: str = None,
    time: str = None,
    custom_attributes: Optional[dict] = None,
) -> str:
  """Publishes a structured CloudEvent to the Eventarc Advanced Bus.

  Args:
      bus: The full resource name of the Eventarc Bus.
      type: The semantic CloudEvent type (e.g., my-agent.response).
      source: The URI reference for the event producer (e.g., my-agent).
      data: The event payload. Can be a string, dict, list, or bytes.
      datacontenttype: Content type of the data value.
      subject: Describes the subject of the event.
      id: The CloudEvent ID. Leave blank to auto-generate a UUIDv4.
      time: The occurrence time. Leave blank to use the current UTC time.
      custom_attributes: Optional dictionary of custom string key-value pairs
        for Eventarc routing.
  """
  if bus == "mock-bus-for-testing":
    print(f"MOCK Eventarc: Type={type}, Source={source}, Data={data}")
    return f"Success: Event {id or 'mock-id'} published to {bus} (MOCK)."

  # Initialize the Eventarc Publishing client
  client = PublisherClient()

  # 1. Handle auto-generated fields
  event_id = id if id else str(uuid.uuid4())
  event_time = (
      time
      if time
      else datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
  )

  # 2. Prepare CloudEvent attributes
  attributes = {
      "time": CloudEvent.CloudEventAttributeValue(ce_string=event_time)
  }
  if subject:
    attributes["subject"] = CloudEvent.CloudEventAttributeValue(
        ce_string=subject
    )

  # Inject custom attributes for routing ---
  prefix = "EVENTARC_ATTR_"
  for key, value in os.environ.items():
    if key.startswith(prefix):
      attr_name = key[len(prefix) :].lower()
      if custom_attributes is None:
        custom_attributes = {}
      if attr_name not in custom_attributes:
        custom_attributes[attr_name] = value

  if custom_attributes:
    for key, value in custom_attributes.items():
      # Eventarc expects attributes to be explicitly typed as strings
      attributes[key] = CloudEvent.CloudEventAttributeValue(
          ce_string=str(value)
      )

  # 3. Handle data mapping and datacontenttype inference
  text_data = None
  binary_data = None

  if data is not None:
    if isinstance(data, (dict, list)):
      text_data = json.dumps(data)
      final_content_type = datacontenttype or "application/json"
    elif isinstance(data, str):
      text_data = data
      final_content_type = datacontenttype or "text/plain"
    elif isinstance(data, bytes):
      binary_data = data
      final_content_type = datacontenttype or "application/octet-stream"
    else:
      text_data = str(data)
      final_content_type = datacontenttype or "text/plain"

    attributes["datacontenttype"] = CloudEvent.CloudEventAttributeValue(
        ce_string=final_content_type
    )

  # 4. Build the CloudEvent object
  event_kwargs = {
      "id": event_id,
      "source": source,
      "spec_version": "1.0",
      "type_": type,
      "attributes": attributes,
  }

  if text_data is not None:
    event_kwargs["text_data"] = text_data
  if binary_data is not None:
    event_kwargs["binary_data"] = binary_data

  event = CloudEvent(**event_kwargs)

  # 5. Build the Publish Request
  request = PublishRequest(message_bus=bus, proto_message=event)

  try:
    # 6. Execute the publish call
    client.publish(request=request)
    return f"Success: Event {event_id} published to {bus}."
  except Exception as e:
    return f"Error publishing event: {str(e)}"
