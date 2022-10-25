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

echo "Create a service account named $TRIGGER_SERVICE_ACCOUNT to be used by GKE triggers"
# Eventarc for GKE triggers require a user-provided SA to be used by the Event
# Forwarder to pull events from Pub/Sub
gcloud iam service-accounts create $TRIGGER_SERVICE_ACCOUNT

echo "Add right roles to the service account"
# The SA must be granted the following roles:
# * roles/pubsub.subscriber
# * roles/monitoring.metricWriter
# * roles/eventarc.eventReceiver (Only for AuditLog triggers that will be added
#   in a later script).
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$TRIGGER_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/pubsub.subscriber

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$TRIGGER_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/monitoring.metricWriter

echo "Create a Pub/Sub trigger named $TRIGGER_PUBSUB_NAME"
gcloud eventarc triggers create $TRIGGER_PUBSUB_NAME \
  --destination-gke-cluster=$CLUSTER_NAME \
  --destination-gke-location=$REGION \
  --destination-gke-namespace=default \
  --destination-gke-service=$SERVICE_NAME \
  --destination-gke-path=/ \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
  --location=$REGION \
  --service-account=$TRIGGER_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
