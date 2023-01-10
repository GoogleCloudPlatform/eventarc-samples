#!/bin/bash

# Copyright 2023 Google LLC
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

source ../../config.sh

echo "Publish to the channel connection $CHANNEL_CONNECTION_ID from C# client library with the right event type and attributes"
dotnet run $PROJECT_ID $REGION $CHANNEL_CONNECTION_ID

echo "Wait 10 seconds and read the logs of $SERVICE_NAME service to see the received custom event"
sleep 10
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit 5
