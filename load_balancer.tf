# External HTTPS Load Balancer
# The LB is the only internet-facing component — application and database are private
# Cloud Armor WAF policy is attached (defined in platform repo)

# Health check for backend instances
resource "google_compute_health_check" "app" {
  name                = "medical-imaging-health-check"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  https_health_check {
    port         = 443
    request_path = "/health"
  }
}

# Backend service with Cloud Armor WAF policy from the platform repo
# TODO: add log_config block once access log bucket is provisioned (tracked in INFRA-204)
resource "google_compute_backend_service" "app" {
  name                  = "medical-imaging-backend-service"
  protocol              = "HTTPS"
  port_name             = "https"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.app.id]
  load_balancing_scheme = "EXTERNAL"

  # Cloud Armor policy defined and managed in gcp-imaging-platform repo
  security_policy = data.terraform_remote_state.platform.outputs.cloud_armor_policy_id

  # NOTE: No backends attached yet — in production, instance groups would be added here
}

# URL map to route requests to the backend service
resource "google_compute_url_map" "app" {
  name            = "medical-imaging-url-map"
  default_service = google_compute_backend_service.app.id
}

# Managed SSL certificate
resource "google_compute_managed_ssl_certificate" "app" {
  name = "medical-imaging-ssl-cert"

  managed {
    domains = ["imaging.example.com"]
  }
}

# HTTPS target proxy
resource "google_compute_target_https_proxy" "app" {
  name             = "medical-imaging-https-proxy"
  url_map          = google_compute_url_map.app.id
  ssl_certificates = [google_compute_managed_ssl_certificate.app.id]
}

# Global forwarding rule (external IP + port binding)
resource "google_compute_global_forwarding_rule" "app" {
  name                  = "medical-imaging-forwarding-rule"
  target                = google_compute_target_https_proxy.app.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}
