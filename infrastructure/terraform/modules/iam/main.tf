locals {
  # Normalize app_name: replace underscores with dashes (GCP only allows a-z, 0-9, -)
  app_name_normalized = replace(var.app_name, "_", "-")
}

# Service Account for Cloud Run to run the application
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${local.app_name_normalized}-run-sa"
  display_name = "Cloud Run Service Account"
}

# Service Account for GitHub Actions to deploy the Infrastructure written in Terraform
resource "google_service_account" "github_actions_sa" {
  account_id   = "${local.app_name_normalized}-gh-sa"
  display_name = "GitHub Actions Service Account"
}

# Give the permission to push Docker image to Artifact Registry for GitHub Actions
resource "google_project_iam_member" "ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Give the permission to manage Cloud Run for GitHub Actions
resource "google_project_iam_member" "run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Allow GitHub Actions Service Account to act as Cloud Run Service Account
resource "google_service_account_iam_member" "sa_user" {
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Configure Workload Identity Federation (Don't export JSON key file)
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "${local.app_name_normalized}-pool-v2"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${local.app_name_normalized}-prov-v2"

  attribute_condition = "attribute.repository == \"${var.gh_repo}\""

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Attach a policy so that the specific repository can emulate a GitHub Actions Service Account.
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.gh_repo}"
}
