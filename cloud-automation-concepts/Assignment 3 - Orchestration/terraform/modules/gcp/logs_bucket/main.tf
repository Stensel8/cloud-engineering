resource "google_storage_bucket" "logs" {
  name                        = "cloudshirt-logs-${random_id.suffix.hex}"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  logging {
    log_bucket        = google_storage_bucket.logs_access.name
    log_object_prefix = "logs-bucket-access/"
  }
}

resource "google_storage_bucket" "logs_access" {
  #checkov:skip=CKV_GCP_62:Dit is de logging-doelbucket zelf; circulair loggen niet mogelijk
  name                        = "cloudshirt-logs-access-${random_id.suffix.hex}"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "logs_bucket_url" {
  value = "gs://${google_storage_bucket.logs.name}"
}
