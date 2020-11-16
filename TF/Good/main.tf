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

# ## Assign IAM Permissions
# resource "google_project_iam_member" "k8s-member" {
#   count   = "${length(var.iam_roles)}"
#   project = "${var.gcp-project-name}"
#   role    = "${element(values(var.iam_roles), count.index)}"
#   member  = "serviceAccount:${google_service_account.gke_node.email}"
# }


## Create GKE Cluster The Right Way
resource "google_container_cluster" "more-secure" {
    provider    = google-beta
    name        = "more-secure"
    location    = var.region
    
    remove_default_node_pool = true
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
        master_ipv4_cidr_block = "10.15.0.0/28"
    }


    node_config {
        oauth_scopes = [
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring"
        ]

        metadata = {
            disable-legacy-endpoints = "true"
        }

          service_account = "${google_service_account.gke_node.email}"
    }

    timeouts {
        create = "30m"
        update = "40m"
    }
}

resource "google_container_node_pool" "pre-empt_nodepool1" {
  provider    = google-beta
  name       = "pre-empt-noodepool1"
  location   = "${var.region}"
  cluster    = "${google_container_cluster.more-secure.name}"
  node_count = 1


  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
        node_metadata = "GKE_METADATA_SERVER"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}
