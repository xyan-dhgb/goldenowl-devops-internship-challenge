#Testing CI Pipeline with Terraform
module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  app_name   = var.app_name
  gh_repo    = var.gh_repo
}

module "artifact_registry" {
  source   = "./modules/artifact_registry"
  region   = var.region
  app_name = var.app_name
}

module "cloud_run" {
  source                = "./modules/cloud_run"
  project_id            = var.project_id
  region                = var.region
  app_name              = var.app_name
  image_url             = "us-docker.pkg.dev/cloudrun/container/hello" # Placeholder for the first run
  service_account_email = module.iam.cloud_run_sa_email
}

module "load_balancer" {
  source         = "./modules/load_balancer"
  project_id     = var.project_id
  region         = var.region
  app_name       = var.app_name
  cloud_run_name = module.cloud_run.service_name
}
