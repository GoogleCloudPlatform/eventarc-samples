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

echo "Get the project id"
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "Set the Eventarc location and Cloud Run region"
REGION=us-central1
gcloud config set eventarc/location $REGION
gcloud config set run/region $REGION

echo "Enable required services"
gcloud services enable  \
  eventarc.googleapis.com \
  eventarcpublishing.googleapis.com \
  run.googleapis.com

echo "Create a channel"
CHANNEL_NAME=hello-custom-events-channel
gcloud eventarc channels create $CHANNEL_NAME

echo "Deploy the hello service"
SERVICE_NAME=hello
gcloud run deploy $SERVICE_NAME \
  --image=gcr.io/cloudrun/hello \
  --allow-unauthenticated

echo "Create a trigger using the channel, routing to the hello service with custom event filters"
gcloud eventarc triggers create hello-custom-events-trigger \
  --channel=$CHANNEL_NAME \
  --destination-run-service=$SERVICE_NAME \
  --destination-run-region=$REGION \
  --event-filters="type=mycompany.myorg.myproject.v1.myevent" \
  --event-filters="someattribute=somevalue" \
  --service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
