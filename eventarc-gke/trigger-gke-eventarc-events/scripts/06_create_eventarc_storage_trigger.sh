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

echo "Create a bucket with name $BUCKET_NAME"
gcloud storage buckets create --location=$REGION gs://$BUCKET_NAME

echo "Add pubsub.publisher role to the Cloud Storage service account"
# This is needed for Cloud Storage triggers
SERVICE_ACCOUNT_STORAGE=$(gcloud storage service-agent --project=$PROJECT_ID)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT_STORAGE \
    --role roles/pubsub.publisher

TRIGGER_STORAGE_NAME=trigger-storage-gke
echo "Create a Cloud Storage trigger named $TRIGGER_STORAGE_NAME"
gcloud eventarc triggers create $TRIGGER_STORAGE_NAME \
  --destination-gke-cluster=$CLUSTER_NAME \
  --destination-gke-location=$REGION \
  --destination-gke-namespace=default \
  --destination-gke-service=$SERVICE_NAME \
  --destination-gke-path=/ \
  --event-filters="type=google.cloud.storage.object.v1.finalized" \
  --event-filters="bucket=$BUCKET_NAME" \
  --location=$REGION \
  --service-account=$TRIGGER_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
