variable "project_id" {
  description = "Project ID on GCP"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "app_name" {
  description = "The name of the application used for naming resources"
  type        = string
}

variable "gh_repo" {
  description = "GitHub repository name (format: owner/repo) for configuring Workload Identity"
  type        = string
}
