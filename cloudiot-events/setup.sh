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

echo "Set the Eventarc location and Cloud Run region"
REGION=us-central1
gcloud config set eventarc/location $REGION
gcloud config set run/region $REGION

echo "Enable required services"
gcloud services enable \
  cloudiot.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com

echo "Create a service account for Eventarc Cloud IoT trigger"
SA_NAME=eventarc-cloudiot-sa-account
gcloud iam service-accounts create $SA_NAME \
    --display-name "Eventarc Cloud IoT Service Account"

echo "Assign eventReceiver role to the service account"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/eventarc.eventReceiver"

echo "Deploy the hello Cloud Run service to receive events"
SERVICE_NAME=hello
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/cloudrun/$SERVICE_NAME \
  --allow-unauthenticated

echo "Create a Cloud IoT trigger to listen for registry creation events with test-registry-* name"
gcloud eventarc triggers create cloudiot-trigger \
  --destination-run-service=$SERVICE_NAME \
  --destination-run-region=$REGION \
  --event-filters="type=google.api.cloud.iot.v1.registryCreated" \
  --event-filters-path-pattern="registry=**/test-registry-*" \
  --service-account=$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com

