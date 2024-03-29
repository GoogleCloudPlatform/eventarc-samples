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

echo "Enable required services for Eventarc and Eventarc GKE destinations"
gcloud services enable eventarc.googleapis.com \
  cloudresourcemanager.googleapis.com

echo "Enable Eventarc to manage GKE clusters"
# Eventarc creates a separate Event Forwarder pod for each trigger targeting a
# GKE service, and  requires explicit permissions to make changes to the
# cluster. This is done by granting permissions to a special service account
# (the Eventarc P4SA) to manage resources in the cluster. This needs to be done
# once per Google Cloud project.
gcloud eventarc gke-destinations init