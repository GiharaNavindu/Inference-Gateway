terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  region = "us-central1"
}

data "google_project" "current" {}

resource "google_container_cluster" "aiforge_cluster" {
  name     = "aiforge-cluster"
  location = "us-central1-b"

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  workload_identity_config {
    workload_pool = "${data.google_project.current.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "gpu_pool" {
  name       = "l4-gpu-pool"
  location   = "us-central1-b"
  cluster    = google_container_cluster.aiforge_cluster.name
  node_count = 1

  node_config {
    machine_type = "g2-standard-4" 
    disk_size_gb = 100
    disk_type    = "pd-balanced"

    guest_accelerator {
      type  = "nvidia-l4"
      count = 1
      gpu_driver_installation_config {
        gpu_driver_version = "LATEST"
      }
    }
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
