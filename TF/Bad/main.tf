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

resource "google_container_cluster" "default" {
  provider    = google-beta
  name = "default-cluster"
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }


  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "google_container_node_pool" "pre-empt_nodepool1" {
  name       = "pre-empt-noodepool1"
  location   = var.region
  cluster    = google_container_cluster.default.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}