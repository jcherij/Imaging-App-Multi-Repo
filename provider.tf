terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "medical-imaging-tfstate"
    prefix = "app"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  default_labels = {
    application = "medical-imaging-portal"
    environment = var.environment
    managed-by  = "terraform"
    layer       = "app"
    data-class  = "phi"
  }
}

# Pull outputs from the platform repo's remote state
# Run `terraform apply` in gcp-imaging-platform first, then this repo
data "terraform_remote_state" "platform" {
  backend = "gcs"
  config = {
    bucket = "medical-imaging-tfstate"
    prefix = "platform"
  }
}
