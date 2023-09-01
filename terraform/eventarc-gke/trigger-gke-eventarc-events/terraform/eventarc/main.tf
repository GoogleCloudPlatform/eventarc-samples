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

# [START terraform_eventarc_gke_initialize]
# Used to retrieve project_number later
data "google_project" "project" {}

# Enable Eventarc to manage GKE clusters
# This is usually done with: gcloud eventarc gke-destinations init
#
# Eventarc creates a separate Event Forwarder pod for each trigger targeting a
# GKE service, and  requires explicit permissions to make changes to the
# cluster. This is done by granting permissions to a special service account
# (the Eventarc P4SA) to manage resources in the cluster. This needs to be done
# once per Google Cloud project.

# This identity is created with: gcloud beta services identity create --service eventarc.googleapis.com
# This local variable is used for convenience
locals {
  eventarc_sa = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "computeViewer" {
  project = data.google_project.project.id
  role    = "roles/compute.viewer"
  member  = local.eventarc_sa
}

resource "google_project_iam_member" "containerDeveloper" {
  project = data.google_project.project.id
  role    = "roles/container.developer"
  member  = local.eventarc_sa
}

resource "google_project_iam_member" "serviceAccountAdmin" {
  project = data.google_project.project.id
  role    = "roles/iam.serviceAccountAdmin"
  member  = local.eventarc_sa
}
# [END terraform_eventarc_gke_initialize]


# [START terraform_eventarc_configure_serviceaccount]
# Create a service account to be used by GKE trigger
resource "google_service_account" "eventarc_gke_trigger_sa" {
  account_id   = "eventarc-gke-trigger-sa"
  display_name = "Evenarc GKE Trigger Service Account"
}

# Grant permission to receive Eventarc events
resource "google_project_iam_member" "eventreceiver" {
  project = data.google_project.project.id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc_gke_trigger_sa.email}"
}

# Grant permission to subscribe to Pub/Sub topics
resource "google_project_iam_member" "pubsubscriber" {
  project = data.google_project.project.id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.eventarc_gke_trigger_sa.email}"
}

# [END terraform_eventarc_configure_serviceaccount]


# [START storage_terraform_eventarc_gke]
# Create a Cloud Storage bucket
resource "google_storage_bucket" "default" {
  name          = "trigger-gke-${data.google_project.project.name}"
  location      = "us-central1"
  force_destroy = true

  uniform_bucket_level_access = true
}

# Grant the Cloud Storage service account permission to publish pub/sub topics
data "google_storage_project_service_account" "gcs_account" {}
resource "google_project_iam_member" "pubsubpublisher" {
  project = data.google_project.project.id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}
# [END storage_terraform_eventarc_gke]

# [START eventarc_terraform_gke_trigger]
# Create an Eventarc trigger, routing Storage events to GKE
resource "google_eventarc_trigger" "default" {
  name     = "trigger-storage-gke-tf"
  location = "us-central1"

  # Capture objects changed in the bucket
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.default.name
  }

  # Send events to GKE service
  destination {
    gke {
      cluster   = "eventarc-cluster"
      location  = "us-central1"
      namespace = "default"
      path      = "/"
      service   = "hello-gke"
    }
  }

  service_account = google_service_account.eventarc_gke_trigger_sa.email
}
# [END eventarc_terraform_gke_trigger]
