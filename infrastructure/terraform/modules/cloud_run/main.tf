resource "google_cloud_run_v2_service" "default" {
  name     = "${var.app_name}-service"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Only allow traffic from Load Balancer

  template {
    containers {
      image = var.image_url
      ports {
        container_port = 3000
      }
    }
    service_account = var.service_account_email
    scaling {
      min_instance_count = 0
      max_instance_count = 5 # Support Auto-scaling up to 5 instances to save costs
    }
  }
}

# Allow public access (no login token required) to  Cloud Run
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.default.location
  project  = google_cloud_run_v2_service.default.project
  service  = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
