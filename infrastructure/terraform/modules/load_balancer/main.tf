# Serverless Network Endpoint Group (NEG) points to Cloud Run
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.app_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = var.cloud_run_name
  }
}

# Backend Service
resource "google_compute_backend_service" "default" {
  name                  = "${var.app_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

# URL Map
resource "google_compute_url_map" "default" {
  name            = "${var.app_name}-url-map"
  default_service = google_compute_backend_service.default.id
}

# Target HTTP Proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.app_name}-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Global Forwarding Rule (Frontend IP)
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "${var.app_name}-forwarding-rule"
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}
