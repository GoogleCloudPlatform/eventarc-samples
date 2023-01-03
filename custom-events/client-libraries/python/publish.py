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
# [START eventarc_custom_publish_python]
import sys
import argparse
import logging

from cloudevents.http import CloudEvent
from cloudevents.conversion import to_json
from google.cloud.eventarc_publishing_v1.types import publisher
from google.cloud.eventarc_publishing_v1.services.publisher import client

parser = argparse.ArgumentParser(description="Arguments to publish an event with Eventarc Publisher API")
parser.add_argument('--channel', type=str, help='Name of the channel on which the event should be published')
parser.add_argument('--log', type=str, choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], default='ERROR')

logger = logging.getLogger()
console_handler = logging.StreamHandler(sys.stdout)
logger.addHandler(console_handler)

def main():
  args = parser.parse_args()
  logger.setLevel(args.log)

  # Build a valid CloudEvent
  # The CloudEvent "id" and "time" are auto-generated if omitted and "specversion" defaults to "1.0".
  attributes = {
      "type": "mycompany.myorg.myproject.v1.myevent",
      "source": "//event/from/python",
      "datacontenttype": "application/json",
      # Note: someattribute and somevalue have to match with the trigger!
      "someattribute": "somevalue"
  }
  data = {"message": "Hello World from Python"}
  event = CloudEvent(attributes, data)

  logger.debug('Prepared CloudEvent:')
  logger.debug(event)

  request = publisher.PublishEventsRequest()
  request.channel = args.channel
  request.text_events.append(to_json(event))

  logger.debug('Prepared publishing request:')
  logger.debug(request);

  publisher_client = client.PublisherClient()
  response = publisher_client.publish_events(request)
  logger.info('Event published')
  logger.debug(f'Result: {response}')


if __name__ == '__main__':
  main()
# [END eventarc_custom_publish_python]
