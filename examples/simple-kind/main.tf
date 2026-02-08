locals {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca)
  client_key             = base64decode(var.kubernetes_cluster_key)
  client_certificate     = base64decode(var.kubernetes_cluster_cert)
}

module "observability" {
  source = "github.com/alessskeno/terraform-k8s-observability//modules/observability?ref=v1.0.0"
  # source = "../../modules/observability" # local development

  # ============================================================================
  # 1. Environment & Global Settings
  # ============================================================================
  env    = "dev"
  domain = var.domain

  cluster_engine = "kind"     # kind, rke2, etc.
  dns_service    = "kube-dns" # kube-dns, rke2-coredns-rke2-coredns

  traefik_enabled    = true
  ingress_class_name = "traefik"

  # ============================================================================
  # 2. Storage Configuration
  # ============================================================================
  # MinIO (Self-Hosted Object Storage) - Recommended for Plug & Play
  minio_enabled    = true
  minio_access_key = var.minio_access_key
  minio_secret_key = var.minio_secret_key

  # External S3 (Used only if minio_enabled = false)
  s3_endpoint    = var.s3_endpoint
  s3_region      = var.s3_region
  s3_access_key  = var.s3_access_key
  s3_secret_key  = var.s3_secret_key
  s3_bucket_name = var.s3_bucket_name

  # ============================================================================
  # 3. Observability Components (Toggle Features)
  # ============================================================================
  cert_manager_enabled = true

  prometheus_enabled = true
  grafana_enabled    = true

  loki_enabled  = true
  mimir_enabled = false
  tempo_enabled = true

  alloy_enabled         = true
  opentelemetry_enabled = true

  # ============================================================================
  # 4. Storage & Persistence Configuration
  # ============================================================================
  minio_storage_size             = "3Gi"
  loki_storage_size              = "3Gi"
  tempo_storage_size             = "5Gi"
  mimir_storage_size             = "2Gi"
  prometheus_server_storage_size = "5Gi"
  alertmanager_storage_size      = "5Gi"
  grafana_storage_size           = "5Gi"

  storage_class = "standard"

  # ============================================================================
  # 5. Security & Credentials
  # ============================================================================
  grafana_admin_password = var.grafana_admin_password

  # Cert Configuration
  # Use "selfsigned-issuer" for local/dev (generates CA automatically)
  cert_manager_cluster_issuer = "cluster-ca-issuer"
}
