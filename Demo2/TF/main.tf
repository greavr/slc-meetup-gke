// Provider Base
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

// Google Cloud provider & Beta
provider "google" {
  project = var.gcp-project-name
  region = var.region
}

provider "google-beta" {
  project = var.gcp-project-name
}

## Wordpress Service Account
resource "google_service_account" "gke-wordpress-sa" {
  account_id   = "gsa-wli"
  display_name = "Kubernetes Wordpress SA"
}

## Assign IAM Permissions
resource "google_project_iam_member" "gke-wordpress-roles" {
  for_each = toset(var.iam_roles)
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke-wordpress-sa.email}"
}

## Cloud SQL Instance
resource "google_sql_database" "database" {
  name     = "cloudsql-database"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database_instance" "instance" {
  name   = "cloudsql-database-instance-2"
  region = "us-west2"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }
  }
  deletion_protection  = "true"
}

resource "google_sql_user" "users" {
  name     = "wordpress_sql_user"
  instance = google_sql_database_instance.instance.name
  host     = "me.com"
  password = "gke_sql_wordpress_pass"
}

resource "google_compute_network" "private_network" {
  provider = google-beta

  name = "private-network"
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
