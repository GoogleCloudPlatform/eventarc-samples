provider "google" {
  project = lookup(var.workspace_projects, terraform.workspace, var.workspace_projects["demo"])
  region  = var.region
}

provider "google-beta" {
  project = lookup(var.workspace_projects, terraform.workspace, var.workspace_projects["demo"])
  region  = var.region
}

data "google_project" "project" {}

# Read common infrastructure state
data "terraform_remote_state" "infra" {
  backend = "gcs"
  config = {
    bucket = var.bucket
    prefix = "terraform/state/infra"
  }
}

locals {
  # 1. Parse the Universal YAML Config
  yaml_config = yamldecode(templatefile("${path.module}/${var.config_file}", {
    project_id          = var.workspace_projects["demo"]
    region              = var.region
    external_project_id = var.workspace_projects["external"]
  }))
  services                  = local.yaml_config["services"]
  standalone_pipelines      = lookup(local.yaml_config, "pipelines", {})
  default_project           = lookup(local.yaml_config, "project", lookup(var.workspace_projects, terraform.workspace, var.workspace_projects["demo"]))
  default_region            = lookup(local.yaml_config, "region", var.region)
  artifact_registry_project = lookup(local.yaml_config, "artifact_registry_project", var.workspace_projects["demo"])
  eventarc_bus              = lookup(local.yaml_config, "eventarc_bus", data.terraform_remote_state.infra.outputs.message_bus_name)
  bus_project_extracted     = split("/", local.eventarc_bus)[1]

  services_with_pipelines = {
    for k, v in local.services : k => v if lookup(v, "pipeline", null) != null
  }

  external_cr_pipelines = {
    for k, v in local.standalone_pipelines : k => v if lookup(lookup(v, "destination", {}), "http", null) != null && lookup(lookup(v.destination, "http", {}), "cr_service", null) != null
  }

  unified_pipelines = merge(
    {
      for k, v in local.services_with_pipelines : k => {
        is_service = true
        pipeline   = v.pipeline
        uri        = try(google_cloud_run_v2_service.service[k].uri, "https://pending-import")
        labels     = lookup(v.pipeline, "labels", null) != null ? try(tomap(v.pipeline.labels), {}) : lookup(v, "labels", {})
        project    = lookup(v, "project", local.default_project)
        region     = lookup(v, "region", local.default_region)
      }
    },
    {
      for k, v in local.standalone_pipelines : k => {
        is_service     = false
        pipeline       = v
        uri            = lookup(v.destination.http, "cr_service", null) != null ? data.google_cloud_run_v2_service.external_service[k].uri : lookup(v.destination.http, "uri", "")
        labels         = lookup(v, "labels", null) != null ? try(tomap(v.labels), {}) : {}
        project        = local.default_project
        region         = lookup(v, "region", local.default_region)
        target_project = lookup(v.destination.http, "project", local.default_project)
      }
    }
  )

  projects_with_pipelines = toset([
    for k, v in local.unified_pipelines : v.project
  ])

  service_to_invoker = merge(
    {
      for k, v in local.services_with_pipelines : k => {
        email   = try(google_service_account.invoker_sa[k].email, "pending-import@email.com")
        project = lookup(v, "project", local.default_project)
        region  = lookup(v, "region", local.default_region)
      }
    },
    {
      for k, v in local.external_cr_pipelines : v.destination.http.cr_service => {
        email   = try(google_service_account.invoker_sa[k].email, "pending-import@email.com")
        project = lookup(v.destination.http, "project", local.default_project)
        region  = lookup(v.destination.http, "region", local.default_region)
      }
    }
  )

  services_with_armor = {
    for k, v in local.services : k => v.model_armor if lookup(v, "model_armor", null) != null
  }

  projects_needing_armor = distinct([
    for k, v in local.services_with_armor : lookup(local.services[k], "project", local.default_project)
  ])

  services_with_url = {
    for k, v in local.services : k => v if lookup(v, "url", null) != null
  }

  # 2. Hash shared dependencies
  shared_tools_hash = sha1(join("", [for f in fileset("${path.module}/services/shared_tools", "**") : filesha1("${path.module}/services/shared_tools/${f}")]))

  # 3. Hash service specific folders
  service_hashes = {
    for k, v in local.services : k => sha1(join("", concat(
      [local.shared_tools_hash],
      [for f in fileset("${path.module}/${v.src_dir}", "**") : filesha1("${path.module}/${v.src_dir}/${f}")]
    )))
  }
}

data "google_project" "target_project" {
  for_each = toset(distinct(concat(
    [var.workspace_projects["demo"], local.artifact_registry_project, local.bus_project_extracted, local.default_project],
    [for k, v in local.services : lookup(v, "project", local.default_project)]
  )))
  project_id = each.value
}

resource "google_project_service_identity" "eventarc_sa" {
  for_each = data.google_project.target_project
  provider = google-beta
  project  = each.key
  service  = "eventarc.googleapis.com"
}

resource "google_project_service_identity" "run_sa" {
  for_each = data.google_project.target_project
  provider = google-beta
  project  = each.key
  service  = "run.googleapis.com"
}

# Data source for external Cloud Run services targeted by standalone pipelines
data "google_cloud_run_v2_service" "external_service" {
  for_each = local.external_cr_pipelines
  name     = each.value.destination.http.cr_service
  location = lookup(each.value.destination.http, "region", local.default_region)
  project  = lookup(each.value.destination.http, "project", local.default_project)
}

resource "google_project_service" "model_armor_api" {
  for_each           = toset(local.projects_needing_armor)
  project            = each.value
  service            = "modelarmor.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_run_api" {
  for_each           = data.google_project.target_project
  project            = each.key
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc_api" {
  for_each           = local.projects_with_pipelines
  project            = each.key
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "aiplatform_api" {
  for_each           = data.google_project.target_project
  project            = each.key
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_model_armor_template" "service_armor" {
  for_each    = local.services_with_armor
  depends_on  = [google_project_service.model_armor_api]
  project     = lookup(local.services[each.key], "project", local.default_project)
  location    = lookup(local.services[each.key], "region", local.default_region)
  template_id = "${each.key}-armor"

  labels = lookup(local.services[each.key], "labels", null) != null ? (length(local.services[each.key].labels) == 0 ? {} : local.services[each.key].labels) : {}

  template_metadata {
    log_sanitize_operations = true
    log_template_operations = true
    enforcement_type        = "INSPECT_AND_BLOCK"
  }

  filter_config {
    dynamic "pi_and_jailbreak_filter_settings" {
      for_each = lookup(each.value, "pi_and_jailbreak", null) != null ? [lookup(each.value, "pi_and_jailbreak")] : []
      content {
        filter_enforcement = "ENABLED"
        confidence_level   = pi_and_jailbreak_filter_settings.value
      }
    }

    dynamic "malicious_uri_filter_settings" {
      for_each = lookup(each.value, "malicious_uri", null) != null ? [lookup(each.value, "malicious_uri")] : []
      content {
        filter_enforcement = malicious_uri_filter_settings.value
      }
    }
  }
}

# ------------------------------------------------------------------------------
# 3. Services
# ------------------------------------------------------------------------------
resource "terraform_data" "service_build_push" {
  for_each         = local.services
  triggers_replace = local.service_hashes[each.key]

  provisioner "local-exec" {
    command = <<EOT
      # linux/amd64 platform is necessary for cross-platform builds to be compatible with Cloud Run.
      if [ -f "${each.value.src_dir}/docker-compose.yaml" ]; then
        (cd ${each.value.src_dir} && BUILDX_BAKE_ENTITLEMENTS_FS=0 docker buildx bake --set target.platform=linux/amd64 --set *.tags=${var.region}-docker.pkg.dev/${local.artifact_registry_project}/${data.terraform_remote_state.infra.outputs.demo_repo_name}/${each.key}:${local.service_hashes[each.key]})
      else
        docker buildx build --platform linux/amd64 -t ${var.region}-docker.pkg.dev/${local.artifact_registry_project}/${data.terraform_remote_state.infra.outputs.demo_repo_name}/${each.key}:${local.service_hashes[each.key]} ${each.value.src_dir}
      fi
      docker push ${var.region}-docker.pkg.dev/${local.artifact_registry_project}/${data.terraform_remote_state.infra.outputs.demo_repo_name}/${each.key}:${local.service_hashes[each.key]}
    EOT
    interpreter = ["bash", "-c"]
  }
}

resource "google_cloud_run_v2_service" "service" {
  for_each            = local.services
  name                = each.key
  project             = lookup(each.value, "project", local.default_project)
  location            = lookup(each.value, "region", local.default_region)
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  depends_on          = [terraform_data.service_build_push, google_project_service.cloud_run_api, google_project_service.aiplatform_api, google_artifact_registry_repository_iam_member.cloud_run_artifact_reader]

  dynamic "scaling" {
    for_each = lookup(each.value, "min_instances", null) != null || lookup(each.value, "max_instances", null) != null ? [1] : []
    content {
      min_instance_count = lookup(each.value, "min_instances", null)
      max_instance_count = lookup(each.value, "max_instances", null)
    }
  }

  template {
    # Force a new revision when code OR environment variables change
    annotations = {
      "force-deploy" = sha1(join("", [
        local.service_hashes[each.key],
        jsonencode(lookup(each.value, "env_vars", {})),
        tostring(lookup(each.value, "min_instances", "")),
        tostring(lookup(each.value, "max_instances", ""))
      ]))
    }

    # Use specific Publisher Service Account per agent
    service_account = google_service_account.publisher_sa[each.key].email

    labels = lookup(each.value, "labels", null) != null ? (length(each.value.labels) == 0 ? {} : each.value.labels) : {}

    containers {
      image = "${var.region}-docker.pkg.dev/${local.artifact_registry_project}/${data.terraform_remote_state.infra.outputs.demo_repo_name}/${each.key}:${local.service_hashes[each.key]}"

      env {
        name  = "EVENTARC_BUS_NAME"
        value = local.eventarc_bus
      }

      env {
        name  = "URL_PREFIX"
        value = contains(keys(local.services_with_url), each.key) ? "/${each.value.url}" : ""
      }

      env {
        name  = "SERVICE_NAME"
        value = each.key
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = lookup(each.value, "project", local.default_project)
      }

      env {
        name  = "GOOGLE_CLOUD_REGION"
        value = lookup(each.value, "region", local.default_region)
      }

      dynamic "env" {
        for_each = lookup(each.value, "env_vars", {})
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = contains(keys(local.services_with_armor), each.key) ? [1] : []
        content {
          name  = "MODEL_ARMOR_TEMPLATE"
          value = google_model_armor_template.service_armor[each.key].id
        }
      }
    }
  }
}

resource "google_service_account" "publisher_sa" {
  for_each     = local.services
  account_id   = "${each.key}-pub"
  project      = lookup(each.value, "project", local.default_project)
  display_name = "Service Identity - ${each.key}"
}

resource "google_project_iam_member" "service_publisher" {
  for_each = local.services
  project  = local.bus_project_extracted
  role     = "roles/eventarc.messageBusUser"
  member   = "serviceAccount:${google_service_account.publisher_sa[each.key].email}"
}

resource "google_service_account" "invoker_sa" {
  for_each     = local.unified_pipelines
  account_id   = "${each.key}-inv"
  project      = each.value.project
  display_name = "Eventarc Invoker - ${each.key}"
}

resource "google_service_account_iam_member" "eventarc_token_creator" {
  for_each           = local.unified_pipelines
  service_account_id = google_service_account.invoker_sa[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_project_service_identity.eventarc_sa[each.value.project].email}"
}

resource "google_cloud_run_v2_service_iam_member" "service_pipeline_invoker" {
  for_each = local.service_to_invoker
  name     = each.key
  location = each.value.region
  project  = each.value.project
  role     = "roles/run.invoker"
  member   = "serviceAccount:${each.value.email}"
}

resource "google_eventarc_pipeline" "service_pipeline" {
  for_each    = local.unified_pipelines
  pipeline_id = each.key
  depends_on  = [google_project_service_identity.eventarc_sa]
  location    = each.value.region
  project     = each.value.project
  labels      = each.value.labels

  logging_config { log_severity = "DEBUG" }

  dynamic "mediations" {
    for_each = lookup(each.value.pipeline, "transformation", null) != null ? [each.value.pipeline.transformation] : []
    content {
      transformation {
        transformation_template = mediations.value
      }
    }
  }

  dynamic "input_payload_format" {
    for_each = lookup(each.value.pipeline, "input_payload_format", null) != null ? [each.value.pipeline.input_payload_format] : []
    content {
      dynamic "json" {
        for_each = input_payload_format.value.type == "json" ? [1] : []
        content {}
      }

      dynamic "avro" {
        for_each = input_payload_format.value.type == "avro" ? [1] : []
        content {
          schema_definition = input_payload_format.value.schema_definition
        }
      }

      dynamic "protobuf" {
        for_each = input_payload_format.value.type == "protobuf" ? [1] : []
        content {
          schema_definition = input_payload_format.value.schema_definition
        }
      }
    }
  }

  destinations {
    http_endpoint {
      uri = each.value.uri

      message_binding_template = try(
        <<-EOT
        {
          "headers": headers.merge({
            "Content-Type": "application/json",
            "A2A-Version": "1.0",
            "x-envoy-upstream-rq-timeout-ms": "600000"
          }),
          "body": {
            "jsonrpc": "2.0",
            "id": message.id,
            "method": "message/send",
            "params": {
              "message": {
                "role": "user",
                "messageId": message.id,
                "parts": [
                  {
                    "text": ${each.value.pipeline.destination.http.a2a.prompt}
                  }
                ]
              },
              "configuration": {
                "blocking": true
              }
            }
          }
        }
        EOT
        ,
        lookup(lookup(lookup(each.value.pipeline, "destination", {}), "http", {}), "message_binding_template", "")
      )
    }
    authentication_config {
      google_oidc { service_account = google_service_account.invoker_sa[each.key].email }
    }
  }
}

resource "google_eventarc_enrollment" "service_enrollment" {
  for_each      = local.unified_pipelines
  enrollment_id = each.key
  location      = each.value.region
  project       = each.value.project
  labels        = each.value.labels
  message_bus   = data.terraform_remote_state.infra.outputs.message_bus_name
  destination   = google_eventarc_pipeline.service_pipeline[each.key].id
  cel_match     = each.value.pipeline.enrollment_cel_expression
}

resource "google_project_iam_member" "vertex_ai_user" {
  for_each = local.services
  project  = lookup(each.value, "project", local.default_project)
  role     = "roles/aiplatform.user"
  member   = "serviceAccount:${google_service_account.publisher_sa[each.key].email}"
}

resource "google_cloud_run_v2_service_iam_member" "ui_service_invoker" {
  for_each = {
    for k, v in local.services : k => v if lookup(lookup(v, "env_vars", {}), "STARTUP_MODE", "") == "ui"
  }

  name     = google_cloud_run_v2_service.service[each.key].name
  location = google_cloud_run_v2_service.service[each.key].location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.publisher_sa[each.key].email}"
}

resource "google_project_iam_member" "model_armor_user" {
  for_each = local.services_with_armor
  project  = lookup(local.services[each.key], "project", local.default_project)
  role     = "roles/modelarmor.user"
  member   = "serviceAccount:${google_service_account.publisher_sa[each.key].email}"
}

resource "google_project_iam_member" "model_armor_viewer" {
  for_each = local.services_with_armor
  project  = lookup(local.services[each.key], "project", local.default_project)
  role     = "roles/modelarmor.viewer"
  member   = "serviceAccount:${google_service_account.publisher_sa[each.key].email}"
}

resource "google_artifact_registry_repository_iam_member" "cloud_run_artifact_reader" {
  for_each   = data.google_project.target_project
  project    = local.artifact_registry_project
  location   = var.region
  repository = data.terraform_remote_state.infra.outputs.demo_repo_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_project_service_identity.run_sa[each.key].email}"
}
