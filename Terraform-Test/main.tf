provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name = "my-vpc-network"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west2"
  network       = google_compute_network.vpc_network.name
}

resource "google_service_account" "service_account" {
  account_id   = "my-service-account"
  display_name = "My Service Account"
}

resource "google_project_iam_member" "service_account_iam" {
  role   = "roles/editor"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_container_cluster" "private_cluster" {
  name               = "private-cluster"
  location           = var.region
  remove_default_node_pool = true

  master_auth {
    username = "admin"
    password = var.master_password
  }

  network_policy {
    enabled = true
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
  }

  subnetwork = google_compute_subnetwork.subnet.self_link

 node_pool {
    name = "private-pool"
    node_count = 3
    node_config {
      machine_type = "n1-standard-1"
      preemptible  = false
      metadata = {
        disable-legacy-endpoints = "true"
      }
    }
  }

  node_pool {
    name = "autoscaling-pool"
    initial_node_count = 0
    autoscaling {
      min_node_count = 0
      max_node_count = 5
    }
    node_config {
      machine_type = "n1-standard-2"
      preemptible  = true
      metadata = {
        disable-legacy-endpoints = "true"
      }
    }
  }

  resource "google_bigquery_dataset" "vmo2_tech_test" {
  dataset_id                  = "vmo2_tech_test"
  location                    = var.region
  default_partition_expiration_ms = 0
  labels                      = var.labels
}

module "bigquery_access" {
  source = "./modules/bigquery-access"

  bigquery_role_assignment = {
    vmo2_tech_test = {
      role = "roles/bigquery.dataEditor"
      user = "abc@gmail.com"
    }
  }
}

  service_account {
    email = google_service_account.service_account.email
    scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

output "private_cluster_endpoint" {
  value = google_container_cluster.private_cluster.private_cluster_config.0.private_endpoint
}



