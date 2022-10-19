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

echo "Enable required services for Eventarc and Eventarc GKE destinations"
gcloud services enable eventarc.googleapis.com \
  cloudresourcemanager.googleapis.com

echo "Allow Eventarc to manage GKE clusters"
# Eventarc creates a separate Event Forwarder pod for each trigger targeting a
# GKE service, and  requires explicit permissions to make changes to the
# cluster. This is done by granting permissions to a special service account
# (the Eventarc P4SA) to manage resources in the cluster. This needs to be done
# once per Google Cloud project.
gcloud eventarc gke-destinations init

SERVICE_ACCOUNT=eventarc-gke-trigger-sa
echo "Create a service account named $SERVICE_ACCOUNT to be used by GKE triggers"
# Eventarc for GKE triggers require a user-provided SA to be used by the Event
# Forwarder to pull events from Pub/Sub
gcloud iam service-accounts create $SERVICE_ACCOUNT

echo "Add right roles to the service account"
# The SA must be granted the following roles:
# * roles/pubsub.subscriber
# * roles/monitoring.metricWriter
# * roles/eventarc.eventReceiver (Only for AuditLog triggers that will be added
#   in a later script).
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/pubsub.subscriber

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/monitoring.metricWriter