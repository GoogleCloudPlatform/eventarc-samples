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

source config.sh

echo "Enable required services"
gcloud services enable  \
  eventarc.googleapis.com \
  eventarcpublishing.googleapis.com \
  run.googleapis.com

echo "Deploy a Cloud Run service as events destination to log events: $SERVICE_NAME"
gcloud run deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --image=gcr.io/cloudrun/hello \
  --region=$REGION

echo "Create a custom channel for Google Sheets to publish messages to: $CHANNEL_NAME"
gcloud eventarc channels create $CHANNEL_NAME \
  --location=$REGION

echo "Create a trigger: $TRIGGER_NAME"
echo "To connect the channel to the service with an event-filter for a custom event type: $EVENT_TYPE"
gcloud eventarc triggers create $TRIGGER_NAME \
  --channel=$CHANNEL_NAME \
  --destination-run-service=$SERVICE_NAME \
  --destination-run-region=$REGION \
  --event-filters="type=$EVENT_TYPE" \
  --location=$REGION \
  --service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
