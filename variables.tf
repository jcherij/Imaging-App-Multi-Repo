variable "gcp_project_id" {
  description = "GCP project ID — must match the platform repo project"
  type        = string
  default     = "medical-imaging-project"
}

variable "gcp_region" {
  description = "GCP region — must match the platform repo region"
  type        = string
  default     = "us-west1"
}

variable "environment" {
  description = "Environment name (production, staging, dev)"
  type        = string
  default     = "production"
}

variable "db_password" {
  description = "Database master password — stored in Secret Manager after first apply"
  type        = string
  sensitive   = true
  # NOTE: Default provided for bootstrapping only. After first apply, rotate this
  # and reference the Secret Manager version instead.
  default = "MedicalImages2024!"
}

# Reserved for GKE secondary ranges (pods + services) — not yet implemented
# Will be needed when the inference worker moves from Cloud Run to GKE
variable "secondary_subnet_cidr_pods" {
  description = "Secondary IP range for GKE pods"
  type        = string
  default     = "10.4.0.0/16"
}

variable "secondary_subnet_cidr_services" {
  description = "Secondary IP range for GKE services"
  type        = string
  default     = "10.5.0.0/20"
}
