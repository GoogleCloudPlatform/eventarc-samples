variable "region" {
  type        = string
  description = "The region for the Eventarc infrastructure."
}
variable "bus_id" {
  type        = string
  description = "The ID of the Eventarc message bus."
}
variable "config_files" {
  type        = list(string)
  description = "List of YAML config files."
  default     = ["demo.yaml"]
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
  type        = string
  description = "The ID of the Artifact Registry repository."
  default     = "next26-demo-repo"
}
