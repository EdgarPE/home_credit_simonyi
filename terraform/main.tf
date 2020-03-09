# Configuration
// TODO test actual business functionality
// TODO PROD vs DEV config for SQL
// TODO split into multiple files according to conventions
// TODO create module

terraform {
  experiments = [variable_validation]
}

## GCP configuration
variable "project" {
  description = "The ID of the Google Cloud project"
}

variable "region" {
  description = "The region of the Google Cloud project"
  default     = "europe-west1"
  validation {
    condition = contains([
      "asia-east1",
      "asia-northeast1",
      "europe-north1",
      "europe-west1",
      "europe-west4",
      "us-central1",
      "us-east1",
      "us-east4",
      "us-west1"
    ], var.region)
    error_message = "The region must support Cloud Run. See https://cloud.google.com/run/docs/locations."
  }
}

variable "zone" {
  description = "The zone of the Google Cloud project"
  default     = "europe-west1-b"
}
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

## PostgreSQL configuration
variable "pgsql_instance" {
  description = "PostgreSQL instance name"
  default     = "mlflow"
}
resource "random_password" "pgsql_password" {
  length  = 16
  special = false
}

## GCS configuration
variable "artifact_bucket_postfix" {
  description = "GCS artifact bucket name"
  default     = "mlflow-artifacts"
}

## Cloud Run configuration
variable "service_name" {
  description = "Cloud Run service name"
  default     = "mlflow"
}

## Local variables
data "google_client_openid_userinfo" "current" {}
locals {
  email           = data.google_client_openid_userinfo.current.email
  artifact_bucket = "${var.project}-${var.artifact_bucket_postfix}"
}

# Outputs
data "google_client_config" "current" {}

output "email" { value = local.email }
output "project" { value = data.google_client_config.current.project }
output "pgsql_password" { value = random_password.pgsql_password.result }
output "url" { value = google_cloud_run_service.mlflow.status[0].url }

# Resources

## Setup a PostgreSQL instance
resource "google_sql_database_instance" "mlflow" {
  name             = var.pgsql_instance
  database_version = "POSTGRES_9_6"
  settings {
    tier = "db-f1-micro"
  }
}
resource "google_sql_user" "postgres" {
  name     = "postgres"
  instance = google_sql_database_instance.mlflow.name
  password = random_password.pgsql_password.result
}
resource "google_sql_user" "mlflow" {
  name     = "mlflow"
  instance = google_sql_database_instance.mlflow.name
  password = "mlflow"
}
resource "google_sql_database" "mlflow" {
  name     = "mlflow"
  instance = google_sql_database_instance.mlflow.name
}

## Setup GCS
resource "google_storage_bucket" "artifact" {
  name     = local.artifact_bucket
  location = "EU"
}

## Deploy MLFlow to Cloud Run
resource "null_resource" "gcloud_builds_availability" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud builds --help
    EOT
  }
}
resource "null_resource" "cloud_build" {
  depends_on = [null_resource.gcloud_builds_availability]
  provisioner "local-exec" {
    command = <<EOT
      gcloud --project ${var.project} builds submit --tag gcr.io/${var.project}/mlflow-server:latest
    EOT
  }
}

resource "google_project_service" "sql_admin" {
  service = "sqladmin.googleapis.com"
}
resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_service" "mlflow" {
  depends_on = [
    google_sql_database.mlflow,
    google_sql_user.mlflow,
    google_sql_user.postgres,
    google_storage_bucket.artifact,
    null_resource.cloud_build,
    google_project_service.run,
    google_project_service.sql_admin
  ]
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/mlflow-server"
        env {
          name  = "ARTIFACT_ROOT"
          value = "${google_storage_bucket.artifact.name}/artifacts/"
        }
        env {
          name  = "BACKEND_URI"
          value = "postgresql://postgres:${google_sql_user.postgres.password}@/mlflow?host=/cloudsql/${var.project}:${var.region}:${var.pgsql_instance}"
        }
        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = "${var.project}:${var.region}:${var.pgsql_instance}"
        }

        resources {
          limits = {
            "memory" = "512Mi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = "${var.project}:${var.region}:${var.pgsql_instance}"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}


resource "google_cloud_run_service_iam_member" "mlflow" {
  location = var.region
  service  = google_cloud_run_service.mlflow.name

  role = "roles/run.invoker"
  // TODO it seems we don't send the Authorization header by default, and the server isn't accessible
  //member = "projectEditor:${var.project}"
  //member = "user:${local.email}"
  member = "allUsers"
}
