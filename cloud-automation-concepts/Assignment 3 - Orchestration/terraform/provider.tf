provider "aws" {
  region = "us-east-1"
  # profile is intentionally omitted so credentials can come from
  # environment variables, IAM role, or instance profile in CI
}

provider "google" {
  credentials = var.gcp_service_account_json != "" ? var.gcp_service_account_json : null
  project     = var.project_id
  region      = var.gcp_region
  zone        = "${var.gcp_region}-a"
}
