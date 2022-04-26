# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import argparse
import json
import logging

from time import strftime, gmtime

from google.protobuf import timestamp_pb2, any_pb2
from gen import spec_pb2
from google.cloud.eventarc_publishing_v1.types import publisher
from google.cloud.eventarc_publishing_v1.services.publisher import client

parser = argparse.ArgumentParser(description="Arguments to publish an event with Eventarc Publisher API")
parser.add_argument('--channel', type=str, help='Name of the channel on which the event should be published')
parser.add_argument('--event_source', type=str, help='The source of the event.')
parser.add_argument('--event_id', type=str, help='The id of the event.')
parser.add_argument('--event_type', type=str, help='Type of the event. If must be a valid, supported type.')
parser.add_argument('--event_data', type=str, help='The data of the event. If must be a valid json object.')
parser.add_argument('--log', type=str, choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], default='ERROR')

logger = logging.getLogger()
console_handler = logging.StreamHandler(sys.stdout)
logger.addHandler(console_handler)

def main():
  args = parser.parse_args()
  logger.setLevel(args.log)

  try:
    json.loads(args.event_data)
  except:
    logger.error("Provided event data \"${0}\" is not a valid json object".format({args.event_data}))
    sys.exit(1)

  logger.info('Preparing CloudEvent')
  # Build a valid CloudEvent
  event = spec_pb2.CloudEvent()
  event.id = args.event_id
  event.source = args.event_source
  # The spec value must be '1.0'
  event.spec_version = '1.0'
  event.type = args.event_type
  event.text_data = args.event_data
  # The data content type must be 'application/json'
  event.attributes['datacontenttype'].CopyFrom(
      event.CloudEventAttributeValue(ce_string='application/json'))

  timestamp = timestamp_pb2.Timestamp()
  timestamp.GetCurrentTime()
  event.attributes['time'].CopyFrom(event.CloudEventAttributeValue(ce_timestamp=timestamp))

  logger.debug('Prepared event which will be send to publishing backend:')
  logger.debug(event)

  logger.info('Preparing event request')
  request = publisher.PublishEventsRequest()
  request.channel = args.channel
  # The event must be wrapped in protobuf.Any
  packed_event = any_pb2.Any()
  packed_event.Pack(event)
  request.events.append(packed_event)

  logger.debug('Prepared Publishing request:')
  logger.debug(request)

  publisher_client = client.PublisherClient()
  response = publisher_client.publish_events(request)
  logger.info('Event published')
  logger.debug('Result:')
  logger.debug(response)


if __name__ == '__main__':
  main()
