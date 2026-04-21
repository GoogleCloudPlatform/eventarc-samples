provider "google" {
  project = var.workspace_projects["demo"]
  region  = var.region
}

provider "google-beta" {
  project = var.workspace_projects["demo"]
  region  = var.region
}

data "google_project" "project" {}

# ------------------------------------------------------------------------------
# 1. LOCALS
# ------------------------------------------------------------------------------
locals {
  # Read only the specified config files
  yaml_configs = {
    for f in var.config_files : f => yamldecode(templatefile("${path.module}/../config/${f}", {
      project_id          = var.workspace_projects["demo"]
      region              = var.region
      external_project_id = var.workspace_projects["external"]
    }))
  }

  # Merge all services from specified files, using file name + service name as key
  all_services = merge([
    for f, c in local.yaml_configs : {
      for k, v in lookup(c, "services", {}) : "${replace(f, ".yaml", "")}-${k}" => merge(v, {
        file_project = lookup(c, "project", var.workspace_projects["demo"])
        file_region  = lookup(c, "region", var.region)
        original_key = k
      })
    }
  ]...)

  services_with_url = {
    for k, v in local.all_services : k => v if lookup(v, "url", null) != null
  }

  default_service_key = keys(local.services_with_url)[0]
}

# ------------------------------------------------------------------------------
# 2. COMMON INFRASTRUCTURE
# ------------------------------------------------------------------------------

resource "google_project_service" "model_armor_api" {
  service            = "modelarmor.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc_api" {
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service_identity" "eventarc_sa" {
  provider   = google-beta
  service    = "eventarc.googleapis.com"
  depends_on = [google_project_service.eventarc_api]
}

resource "google_project_service" "eventarc_publishing_api" {
  service            = "eventarcpublishing.googleapis.com"
  disable_on_destroy = false
  depends_on         = [google_project_service.eventarc_api]
}

resource "google_project_service" "cloud_run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_build_api" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "aiplatform_api" {
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "demo_repo" {
  location      = var.region
  repository_id = var.artifact_repo_id
  format        = "DOCKER"
  depends_on    = [google_project_service.artifact_registry_api]
}

resource "google_eventarc_message_bus" "bus" {
  message_bus_id = var.bus_id
  location       = var.region
  depends_on     = [google_project_service_identity.eventarc_sa]
}

output "message_bus_name" {
  value = google_eventarc_message_bus.bus.name
}

output "demo_repo_name" {
  value = google_artifact_registry_repository.demo_repo.name
}
