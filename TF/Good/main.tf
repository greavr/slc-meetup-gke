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

## Node Service Account
resource "google_service_account" "gke_node" {
  account_id   = "gke-node-id"
  display_name = "GKE Node SA"
}

## Assign IAM Permissions
resource "google_project_iam_member" "k8s-member" {
  for_each = toset(var.iam_roles)
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

## Create GCR registry
resource "google_container_registry" "registry" {
  project  = var.gcp-project-name
  location = "US"
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.registry.id
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gke_node.email}"
}

## Create GKE Cluster The Right Way
resource "google_container_cluster" "more-secure" {
    provider    = google-beta
    name        = "more-secure-cluster"
    location    = var.region
    
    remove_default_node_pool = false
    initial_node_count       = 1

    # Enable VPC Native
    networking_mode             = "VPC_NATIVE"
    # Enbale Shielded Nodes
    enable_shielded_nodes = true

    master_auth {
        username = ""
        password = ""

        client_certificate_config {
          issue_client_certificate = false
        }
    }

    # Enable Workload Identity
    workload_identity_config {
      identity_namespace = "${var.gcp-project-name}.svc.id.goog"
    }

    # Enable Authorized Networks
    master_authorized_networks_config {
        cidr_blocks {
              cidr_block = "0.0.0.0/0"
              display_name = "World"
        }
    }

    # Setup Private IP
    ip_allocation_policy {
    }

    private_cluster_config {
        enable_private_nodes   = true
        enable_private_endpoint = false
        master_ipv4_cidr_block = "10.17.0.0/28"
    }


    node_config {
      image_type = "COS_CONTAINERD"
      machine_type = "e2-micro"

      service_account = "${google_service_account.gke_node.email}"
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

resource "google_container_node_pool" "safe-nodepool1" {
  provider    = google-beta
  name       = "safe-noodepool1"
  location   = "${var.region}"
  cluster    = "${google_container_cluster.more-secure.name}"
  node_count = 1


  node_config {
    machine_type = "n1-standard-4"
    image_type = "COS_CONTAINERD"

    service_account = "${google_service_account.gke_node.email}"

    # SandBox config
    sandbox_config {
      sandbox_type = "gvisor"
    }

    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }


    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
        node_metadata = "GKE_METADATA_SERVER"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
