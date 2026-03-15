# Cloud Storage bucket for medical imaging files (X-rays, MRIs, CT scans, etc.)
resource "google_storage_bucket" "medical_images" {
  name          = "medical-imaging-files-${var.environment}"
  location      = var.gcp_region
  force_destroy = false
  storage_class = "STANDARD"

  # Uniform bucket-level access enforces IAM-only permissions (no legacy ACLs)
  uniform_bucket_level_access = true

  # ❌ ISSUE #2: Missing explicit CMEK or org policy enforcement - THIS IS A VIOLATION
  # REQUIREMENT: Architecture document requires explicit encryption enforcement
  # IMPACT: Relies solely on default Google-managed encryption without org-level policy
  # FIX REQUIRED: Add CMEK encryption_config block pointing to a KMS key
  #
  # From ARCHITECTURE.md: "Encryption enforcement MUST be explicitly configured
  # beyond default behavior... This is a HIPAA Technical Safeguard requirement
  # (§164.312(a)(2)(iv))"

  versioning {
    enabled = true
  }

  # Lifecycle rule: transition old image versions to Nearline after 90 days (cost optimization)
  lifecycle_rule {
    condition {
      age                   = 90
      with_state            = "ARCHIVED"
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Lifecycle rule: delete non-current versions after 365 days
  lifecycle_rule {
    condition {
      age        = 365
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    data-class   = "phi"
    content-type = "medical-images"
    # environment label removed — was causing label validation errors in staging project
  }
}
