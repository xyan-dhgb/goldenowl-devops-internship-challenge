# Service Account for Cloud Run to run the application
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.app_name}-run-sa"
  display_name = "Cloud Run Service Account"
}

# Service Account for GitHub Actions to deploy the Infrastructure written in Terraform
resource "google_service_account" "github_actions_sa" {
  account_id   = "${var.app_name}-gh-sa"
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
  workload_identity_pool_id = "${var.app_name}-gh-pool"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.app_name}-gh-provider"

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
