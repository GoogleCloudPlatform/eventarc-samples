/**
 * Copyright 2022 Google LLC
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

# Needed for Eventarc and Workflow API enablement
provider "google" {
  project = var.project_id
}

# Enable Pub/Sub API for Eventarc
resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# Enable Workflows API
resource "google_project_service" "workflows" {
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}

# Create a service account for Eventarc trigger and Workflows
resource "google_service_account" "eventarc_workflows_service_account" {
  account_id   = "eventarc-workflows-sa"
  display_name = "Evenarc Workflows Service Account"
}

# Given service account logWriter role, so Workflows can write logs
resource "google_project_iam_binding" "project_binding_eventarc" {
  project = var.project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.eventarc_workflows_service_account.account_id}@${var.project_id}.iam.gserviceaccount.com"
  ]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}

# Give service account workflows.invoker, so Eventarc trigger can invoke Workflows
resource "google_project_iam_binding" "project_binding_workflows" {
  project = var.project_id
  role    = "roles/workflows.invoker"

  members = [
    "serviceAccount:${google_service_account.eventarc_workflows_service_account.account_id}@${var.project_id}.iam.gserviceaccount.com"
  ]

  depends_on = [google_service_account.eventarc_workflows_service_account]
}

# Define and deploy a workflow
resource "google_workflows_workflow" "workflows_example" {
  name            = "pubsub-workflow-tf"
  region          = var.region
  description     = "A sample workflow"
  service_account = google_service_account.eventarc_workflows_service_account.email
  # Imported main workflow YAML file
  source_contents = templatefile("${path.module}/workflow.yaml",{})

  depends_on = [google_project_service.workflows, google_service_account.eventarc_workflows_service_account]
}

# Create an Eventarc trigger routing Pub/Sub events to Workflows
resource "google_eventarc_trigger" "trigger-pubsub-tf" {
  name     = "trigger-pubsub-workflow-tf"
  location = var.region
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    workflow = google_workflows_workflow.workflows_example.id
  }


  service_account = google_service_account.eventarc_workflows_service_account.email

  depends_on = [google_project_service.pubsub, google_project_service.eventarc, google_service_account.eventarc_workflows_service_account]
}
