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

echo "Get authentication credentials to interact with the cluster"
gcloud container clusters get-credentials $CLUSTER_NAME \
    --region $REGION

echo "Creating a deployment named $SERVICE_NAME"
kubectl create deployment $SERVICE_NAME \
    --image=gcr.io/cloudrun/hello

echo "Expose the deployment as a Kubernetes service"
# This creates a service with a stable IP accessible within the cluster.
kubectl expose deployment $SERVICE_NAME \
  --type ClusterIP --port 80 --target-port 8080