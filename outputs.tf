output "load_balancer_ip" {
  description = "External IP address of the HTTPS Load Balancer"
  value       = google_compute_global_forwarding_rule.app.ip_address
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.main.connection_name
  sensitive   = true
}

output "database_private_ip" {
  description = "Cloud SQL instance private IP address"
  value       = google_sql_database_instance.main.private_ip_address
  sensitive   = true
}

output "gcs_bucket_name" {
  description = "Cloud Storage bucket name for medical images"
  value       = google_storage_bucket.medical_images.name
}

output "db_secret_id" {
  description = "Secret Manager secret ID for the database password"
  value       = google_secret_manager_secret.db_password.id
}

output "image_upload_topic" {
  description = "Pub/Sub topic name for image upload events"
  value       = google_pubsub_topic.image_uploaded.name
}

output "image_upload_dlq_topic" {
  description = "Pub/Sub dead-letter topic name"
  value       = google_pubsub_topic.image_uploaded_dlq.name
}
