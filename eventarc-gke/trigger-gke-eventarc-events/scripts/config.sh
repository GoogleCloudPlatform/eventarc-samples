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

export PROJECT_ID=$(gcloud config get-value project)

export CLUSTER_NAME=eventarc-cluster
export REGION=us-central1
export SERVICE_NAME=hello-gke

export TRIGGER_SERVICE_ACCOUNT=eventarc-gke-trigger-sa
export TRIGGER_PUBSUB_NAME=trigger-pubsub-gke

export BUCKET_NAME=eventarc-gcs-$PROJECT_ID