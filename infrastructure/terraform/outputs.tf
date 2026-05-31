output "load_balancer_ip" {
  description = "The system's public IP address for accessing the application."
  value       = module.load_balancer.public_ip
}

output "artifact_registry_url" {
  description = "The URL of the Artifact Registry used for GitHub Actions"
  value       = module.artifact_registry.repository_url
}

output "workload_identity_provider" {
  description = "ID of the Workload Identity Provider used in GitHub Actions"
  value       = module.iam.workload_identity_provider_name
}

output "github_service_account_email" {
  description = "Email of the Service Account for GitHub Actions"
  value       = module.iam.github_actions_sa_email
}
