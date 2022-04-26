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

CHANNEL_NAME=hello-custom-events-channel
echo "Publish to the channel $CHANNEL_NAME from gcloud with the right event type and attributes"
gcloud eventarc channels publish $CHANNEL_NAME \
  --event-id=12345 \
  --event-type=mycompany.myorg.myproject.v1.myevent \
  --event-attributes=someattribute=somevalue \
  --event-source=gcloud \
  --event-data="{\"message\" : \"Hello World from gcloud\"}"

SERVICE_NAME=hello
echo "Check the logs of $SERVICE_NAME service to see the received custom event"
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit 5
