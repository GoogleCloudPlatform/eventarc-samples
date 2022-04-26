#!/bin/bash

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

PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

echo "Publish to the channel $CHANNEL_NAME from curl with the right event type and attributes"

curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: $PROJECT_ID" \
  -X POST \
  -d '{
       "events": [
             {
              "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
              "attributes": {
                "datacontenttype": {"ceString": "application/json"},
                "someattribute": {"ceString": "somevalue"},
                "time": {"ceTimestamp": "2022-03-19T21:29:13.899-04:00"}
              },
              "id": "12345",
              "source": "curl",
              "specVersion": "1.0",
              "textData": "{\"message\": \"Hello world from curl\"}",
              "type": "mycompany.myorg.myproject.v1.myevent"
            }
          ]
      }' \
  https://eventarcpublishing.googleapis.com/v1/projects/$PROJECT_ID/locations/$REGION/channels/$CHANNEL_NAME:publishEvents

SERVICE_NAME=hello
echo "Check the logs of $SERVICE_NAME service to see the received custom event"
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit 5
