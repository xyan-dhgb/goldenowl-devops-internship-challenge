locals {
  app_name_normalized = replace(var.app_name, "_", "-")
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "${local.app_name_normalized}-repo"
  description   = "Docker repository for ${local.app_name_normalized}"
  format        = "DOCKER"
}
