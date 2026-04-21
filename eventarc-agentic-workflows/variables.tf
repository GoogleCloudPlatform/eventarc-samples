variable "region" {
  type        = string
  description = "The region for the Eventarc infrastructure."
}
variable "bus_id" {
  # Unused. Tracked to suppress warnings.
  type = string
}
variable "config_file" {
  type        = string
  description = "Path to YAML configuration file for services and pipelines."
}
variable "bucket" {
  type        = string
  description = "GCS bucket holding Terraform state."
}
variable "workspace_projects" {
  type        = map(string)
  description = "Map of workspace names to GCP project IDs."
}
variable "artifact_repo_id" {
  # Unused. Tracked to suppress warnings.
  type = string
}
