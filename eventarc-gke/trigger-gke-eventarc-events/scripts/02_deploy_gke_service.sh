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

CLUSTER_NAME=eventarc-cluster
REGION=us-central1
echo "Get authentication credentials to interact with the cluster"
gcloud container clusters get-credentials $CLUSTER_NAME \
    --region $REGION

SERVICE_NAME=hello-gke
echo "Creating a deployment named $DEPLOYMENT_NAME"
kubectl create deployment $DEPLOYMENT_NAME \
    --image=gcr.io/cloudrun/hello

echo "Expose the deployment as a Kubernetes service"
# TODO: This creates a service with public IP. Is there a way to set a
# Kubernetes service without public IP and get it used by Eventarc?
kubectl expose deployment $SERVICE_NAME \
  --type LoadBalancer --port 80 --target-port 8080