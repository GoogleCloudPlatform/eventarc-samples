/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# [START terraform_eventarc_gke_enableapis]
# Enable GKE API
resource "google_project_service" "container" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}
# [END terraform_eventarc_gke_enableapis]


# [START gke_terraform_eventarc_cluster]
# Create an auto-pilot GKE cluster
resource "google_container_cluster" "gke_cluster" {
  name     = "eventarc-cluster"
  location = "us-central1"

  enable_autopilot = true

  depends_on = [
    google_project_service.container
  ]
}
# [END gke_terraform_eventarc_cluster]
