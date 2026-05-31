# Enable required GCP APIs before creating any resources
resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",                 # IAM - Service Accounts, Workload Identity
    "iamcredentials.googleapis.com",      # IAM Credentials - Workload Identity Federation tokens
    "cloudresourcemanager.googleapis.com", # Resource Manager - IAM bindings
    "run.googleapis.com",                 # Cloud Run
    "artifactregistry.googleapis.com",    # Artifact Registry
    "compute.googleapis.com",             # Compute Engine - Load Balancer, NEG
    "storage.googleapis.com",             # Cloud Storage - Terraform state bucket
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
