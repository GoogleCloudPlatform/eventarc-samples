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

APP=event-list-generator
REGION=us-central1
GITHUB_TOKEN=YOUR_GITHUB_TOKEN

echo "Get the project id and project number"
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "Enable required services"
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudscheduler.googleapis.com \
  run.googleapis.com

echo "Create a new Artifact Registry repository called containers"
gcloud artifacts repositories create containers --repository-format=docker --location=$REGION

echo "Build and publish the container image"
gcloud builds submit -t $REGION-docker.pkg.dev/$PROJECT_ID/containers/$APP

echo "Create a service account that you will use to run the job"
SERVICE_ACCOUNT=$APP-sa
gcloud iam service-accounts create $SERVICE_ACCOUNT --display-name="Eventarc event list generator service account"

# echo "Grant storage.admin role to the service account"
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#   --role roles/storage.admin \
#   --member serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com

# echo "Create a public bucket to store events lists"
# BUCKET_NAME=$PROJECT_ID-$APP
# gcloud storage buckets create --location=EU gs://$BUCKET_NAME
# gcloud storage buckets update --uniform-bucket-level-access gs://$BUCKET_NAME
# gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME --member=allUsers --role=roles/storage.objectViewer

echo "Create a Cloud Run job"
gcloud run jobs create $APP \
  --image=$REGION-docker.pkg.dev/$PROJECT_ID/containers/$APP \
  --tasks=1 \
  --task-timeout=5m \
  --set-env-vars=GITHUB_TOKEN=$GITHUB_TOKEN \
  --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com

echo "Create a Cloud Scheduler job to run the Cloud Run job every Sunday at midnight"
gcloud scheduler jobs create http $APP --schedule "0 0 * * SUN" \
   --http-method=POST \
   --uri=https://$REGION-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/$PROJECT_ID/jobs/${APP}:run \
   --oauth-service-account-email=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
   --location $REGION