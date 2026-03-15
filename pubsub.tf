# Pub/Sub topics and subscriptions for asynchronous medical image processing
# When a new image is uploaded to GCS, the application publishes an event here
# Downstream consumers (AI inference, DICOM validator, audit logger) subscribe

# Primary topic — image upload events
# Messages include image GCS path, patient study ID, and referring physician
resource "google_pubsub_topic" "image_uploaded" {
  name = "medical-imaging-image-uploaded"

  labels = {
    data-class  = "phi"
    application = "medical-imaging-portal"
  }

  # Retain undelivered messages for 7 days
  message_retention_duration = "604800s"
}

# Dead-letter topic — receives messages that fail processing after max_delivery_attempts
resource "google_pubsub_topic" "image_uploaded_dlq" {
  name = "medical-imaging-image-uploaded-dlq"
}

# Subscription for the AI inference / image analysis worker
resource "google_pubsub_subscription" "image_analysis_worker" {
  name  = "medical-imaging-analysis-worker-sub"
  topic = google_pubsub_topic.image_uploaded.id

  # Allow up to 10 minutes for the analysis worker to finish processing
  ack_deadline_seconds = 600

  # Retain unacknowledged messages for 7 days (matches topic retention)
  message_retention_duration = "604800s"

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.image_uploaded_dlq.id
    max_delivery_attempts = 5
  }
}

# Subscription for the audit/compliance logger
# NOTE: No dead_letter_policy — audit events are considered best-effort
# If this subscription falls behind, messages expire per message_retention_duration
resource "google_pubsub_subscription" "audit_logger" {
  name  = "medical-imaging-audit-logger-sub"
  topic = google_pubsub_topic.image_uploaded.id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"

  retry_policy {
    minimum_backoff = "5s"
    maximum_backoff = "60s"
  }
}

# Grant the app service account (from platform repo) publish rights on the topic
resource "google_pubsub_topic_iam_member" "app_publisher" {
  topic  = google_pubsub_topic.image_uploaded.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.terraform_remote_state.platform.outputs.service_account_email}"
}
