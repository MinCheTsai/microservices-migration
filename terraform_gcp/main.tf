provider "google" {
  credentials = file("./master-streamer-425115-n0-b6bb7b198bdc.json")
  project     = "master-streamer-425115-n0"
  region      = "asia-northeast1"
  zone        = "asia-northeast1-a"
}

resource "google_container_cluster" "primary" {
  name     = "primary-cluster"
  location = "asia-northeast1"

  # deletion_protection = false
  # initial_node_count = 1
  node_locations = ["asia-northeast1-a"]

  node_pool {
    name       = "default-pool"
    node_count = 1
    node_locations = ["asia-northeast1-a"]
    node_config {
      machine_type = "e2-medium"
      disk_size_gb = 20
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = 20
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance"
  database_version = "POSTGRES_15"
  region           = "asia-northeast1"

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_database" "default" {
  name     = "mydatabase"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "default" {
  name     = "pguser"
  instance = google_sql_database_instance.postgres.name
  password = "mypassword"
}

resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "db-credentials"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_credentials_version" {
  secret      = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    username = google_sql_user.default.name
    password = google_sql_user.default.password
    host     = google_sql_database_instance.postgres.connection_name
    port     = 5432
    database = google_sql_database.default.name
  })
}

output "kubeconfig" {
  value = google_container_cluster.primary.endpoint
}

output "client_certificate" {
  value = google_container_cluster.primary.master_auth.0.client_certificate
}

output "client_key" {
  sensitive = true
  value = google_container_cluster.primary.master_auth.0.client_key
}

output "cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
}

output "db_credentials_secret_id" {
  value = google_secret_manager_secret.db_credentials.id
}