resource "google_container_cluster" "primary" {
  name        = "cloudshirt-gke"
  location    = "europe-west4"
  network     = var.vpc_id
  subnetwork  = var.subnet_id

  remove_default_node_pool  = true
  initial_node_count        = 1
  enable_intranode_visibility = true

  ip_allocation_policy {}

  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/16"
      display_name = "vpc-internal"
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  workload_identity_config {
    workload_pool = "${data.google_client_config.current.project}.svc.id.goog"
  }

  authenticator_groups_config {
    security_group = "gke-security-groups@${data.google_client_config.current.project}.iam.gserviceaccount.com"
  }

  resource_labels = {
    project     = "cloudshirt"
    environment = "prod"
  }
}

data "google_client_config" "current" {}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = "europe-west4"
  cluster    = google_container_cluster.primary.name

  node_count = 2

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}
