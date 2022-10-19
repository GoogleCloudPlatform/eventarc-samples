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

BUCKET_NAME=eventarc-gcs-$PROJECT_ID
REGION=us-central1
# This is already created in a previous script
#echo "Create a bucket with name $BUCKET_NAME"
#gsutil mb -l $REGION gs://$BUCKET_NAME

echo "Add eventarc.eventReceiver role to the trigger service account"
# This is needed for Audit Log triggers
SERVICE_ACCOUNT=eventarc-gke-trigger-sa
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/eventarc.eventReceiver

CLUSTER_NAME=eventarc-cluster
SERVICE_NAME=hello-gke
TRIGGER_NAME=trigger-auditlog-storage-gke
echo "Create an Audit Log trigger named $TRIGGER_NAME"
gcloud eventarc triggers create $TRIGGER_NAME \
  --destination-gke-cluster=$CLUSTER_NAME \
  --destination-gke-location=$REGION \
  --destination-gke-namespace=default \
  --destination-gke-service=$SERVICE_NAME \
  --destination-gke-path=/ \
  --event-filters="type=google.cloud.audit.log.v1.written" \
  --event-filters="serviceName=storage.googleapis.com" \
  --event-filters="methodName=storage.objects.create" \
  --event-filters-path-pattern="resourceName=/projects/_/buckets/$BUCKET_NAME/objects/*" \
  --location=$REGION \
  --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
