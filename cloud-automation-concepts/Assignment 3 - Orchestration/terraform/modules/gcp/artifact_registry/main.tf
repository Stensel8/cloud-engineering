resource "google_kms_key_ring" "artifact_keyring" {
  name     = "cloudshirt-artifact-keyring"
  location = var.gcp_region
  project  = var.project_id
}

resource "google_kms_crypto_key" "artifact_key" {
  name            = "cloudshirt-artifact-key"
  key_ring        = google_kms_key_ring.artifact_keyring.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_artifact_registry_repository" "cloudshirt_repo" {
  project       = var.project_id
  location      = var.gcp_region
  repository_id = var.gcp_repo_name
  description   = "Artifact Registry for CloudShirt images"
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.artifact_key.id
}

output "artifact_repo_url" {
  value = google_artifact_registry_repository.cloudshirt_repo.repository_id
}
