resource "google_compute_network" "vpc" {
  name                    = "cloudshirt-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "cloudshirt-subnet"
  region                   = "europe-west4"
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = "10.0.0.0/16"
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "deny_all_ingress" {
  name    = "cloudshirt-deny-all-ingress"
  network = google_compute_network.vpc.name

  deny {
    protocol = "all"
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

resource "google_compute_firewall" "allow_internal" {
  name    = "cloudshirt-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/16"]
  priority      = 1000
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}
