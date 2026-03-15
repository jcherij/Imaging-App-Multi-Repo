# Cloud SQL PostgreSQL instance for image metadata
# Stores patient info, image references, radiologist notes, sharing permissions
resource "google_sql_database_instance" "main" {
  name             = "medical-imaging-db"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  # ❌ ISSUE #1: Single-zone deployment - THIS IS A VIOLATION
  # REQUIREMENT: Architecture document mandates high availability for healthcare systems
  # IMPACT: Creates single point of failure for critical patient care system
  # FIX REQUIRED: Change availability_type to "REGIONAL" for automatic failover
  #
  # From ARCHITECTURE.md: "For a healthcare application where radiologists may need
  # urgent access to images for emergency cases (trauma, stroke, etc.), single-zone
  # deployment is UNACCEPTABLE."

  settings {
    tier              = "db-custom-1-3840"
    availability_type = "ZONAL" # Single-zone — see ISSUE #1 above
    disk_size         = 50
    disk_type         = "PD_SSD"
    # disk_autoresize removed — was causing unexpected billing increases in staging
    # TODO: re-evaluate before GA launch

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.terraform_remote_state.platform.outputs.vpc_id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00" # UTC
      point_in_time_recovery_enabled = true

      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day          = 1 # Monday
      hour         = 4 # 04:00 UTC
      update_track = "stable"
    }
  }

  deletion_protection = true

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database within the Cloud SQL instance
resource "google_sql_database" "medicalimaging" {
  name     = "medicalimaging"
  instance = google_sql_database_instance.main.name
}

# Database user — password sourced from Secret Manager after bootstrap
resource "google_sql_user" "dbadmin" {
  name     = "dbadmin"
  instance = google_sql_database_instance.main.name
  password = var.db_password
}

# Private service networking for Cloud SQL private IP
resource "google_compute_global_address" "private_ip_range" {
  name          = "medical-imaging-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.terraform_remote_state.platform.outputs.vpc_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.terraform_remote_state.platform.outputs.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
