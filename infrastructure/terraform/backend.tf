terraform {
    backend "gcs" {
        bucket  = "goldenowl-infra-gcp-state-bucket"
        prefix  = "terraform/state"
    }
}