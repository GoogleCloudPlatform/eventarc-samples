/**
 * Copyright 2021 Google LLC
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

# [START eventarc_terraform_enableapis]

provider "google" {
  project = var.project_id
}

# Used to retrieve project_number later
data "google_project" "project" {
}

# Enable Cloud Run API
resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# [END eventarc_terraform_enableapis]

# [START eventarc_terraform_cloudrun]

# Deploy Cloud Run service
resource "google_cloud_run_service" "default" {
  name     = "cloudrun-hello-tf"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run]
}

# Make Cloud Run service publicly accessible
resource "google_cloud_run_service_iam_member" "allUsers" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# [END eventarc_terraform_cloudrun]

# [START eventarc_terraform_pubsub]

# Create a Pub/Sub trigger
resource "google_eventarc_trigger" "trigger-pubsub-tf" {
  name     = "trigger-pubsub-tf"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_service.default.name
      region  = var.region
    }
  }

  depends_on = [google_project_service.eventarc]
}

# [END eventarc_terraform_pubsub]

# [START eventarc_terraform_auditlog_storage]

# Create an AuditLog for Cloud Storage trigger
resource "google_eventarc_trigger" "trigger-auditlog-tf" {
  name     = "trigger-auditlog-tf"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }
  matching_criteria {
    attribute = "serviceName"
    value     = "storage.googleapis.com"
  }
  matching_criteria {
    attribute = "methodName"
    value     = "storage.objects.create"
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_service.default.name
      region  = var.region
    }
  }
  service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.eventarc]
}

# [END eventarc_terraform_auditlog_storage]