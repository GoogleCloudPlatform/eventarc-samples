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
APP=event-list-generator
#BUCKET_NAME=$PROJECT_ID-$APP
GITHUB_TOKEN=YOUR_GITHUB_TOKEN
REGION=us-central1
SERVICE_ACCOUNT=$APP-sa

echo "Build and publish the container image"
gcloud builds submit -t $REGION-docker.pkg.dev/$PROJECT_ID/containers/$APP

echo "Update the Cloud Run job to use the new image"
gcloud run jobs update $APP \
  --image=$REGION-docker.pkg.dev/$PROJECT_ID/containers/$APP \
  --tasks=1 \
  --task-timeout=5m \
  --set-env-vars=GITHUB_TOKEN=$GITHUB_TOKEN \
  --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com

echo "Trigger the Cloud Scheduler job to run with the updated Cloud Run job"
gcloud scheduler jobs run $APP --location $REGION