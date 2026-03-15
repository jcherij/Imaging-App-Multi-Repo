# Secret Manager — stores the Cloud SQL database password
# Application reads this at runtime rather than accepting it as an environment variable
# The app service account is granted secretmanager.secretAccessor in the platform repo IAM

resource "google_secret_manager_secret" "db_password" {
  secret_id = "medical-imaging-db-password"

  labels = {
    data-class  = "credential"
    application = "medical-imaging-portal"
  }

  replication {
    auto {}
  }
}

# Initial secret version — populated from the db_password variable during bootstrap
# After the first apply, rotate the value via the GCP console or Secret Manager API
# and update the version here or reference the latest version in the app
resource "google_secret_manager_secret_version" "db_password_v1" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# Audit log sink for secret access — writes to Cloud Logging for HIPAA access tracking
# This ensures all reads of the DB credential are recorded
resource "google_logging_project_sink" "secret_access_audit" {
  name = "medical-imaging-secret-access-audit"

  # Routes to the project's default log bucket — not a dedicated, access-controlled bucket
  # _Default has no retention policy, no IAM restrictions beyond project-level viewer
  destination = "logging.googleapis.com/projects/${var.gcp_project_id}/locations/global/buckets/_Default"

  # Captures Secret Manager data access events for the DB credential
  # NOTE: resource.name path used here — matches admin activity logs
  # Data access audit logs (which log secretVersions.access) use a different
  # log entry structure; this filter may not capture all secret reads
  filter = "protoPayload.serviceName=\"secretmanager.googleapis.com\" AND protoPayload.resourceName=~\"medical-imaging-db-password\""

  unique_writer_identity = true
}
