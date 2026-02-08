
module "cert_manager" {
  source = "./components/cert-manager"

  cert_manager_enabled        = var.cert_manager_enabled
  cert_manager_cluster_issuer = var.cert_manager_cluster_issuer
  domain                      = var.domain
}

module "minio" {
  source = "./components/minio"

  minio_enabled = var.minio_enabled
  access_key    = var.minio_access_key
  secret_key    = var.minio_secret_key

  tempo_enabled = var.tempo_enabled
  loki_enabled  = var.loki_enabled
  mimir_enabled = var.mimir_enabled

  storage_class = var.storage_class
  storage_size  = var.minio_storage_size
}

locals {
  # Common S3 logic: Use local MinIO if enabled, otherwise external variables
  s3_endpoint   = var.minio_enabled ? module.minio.endpoint : var.s3_endpoint
  s3_access_key = var.minio_enabled ? module.minio.access_key : var.s3_access_key
  s3_secret_key = var.minio_enabled ? module.minio.secret_key : var.s3_secret_key
  s3_region     = var.minio_enabled ? "us-east-1" : var.s3_region # MinIO default region

  # Cert Issuer Logic: If using default self-signed, point to our internal issuer
  issuer_name = var.cert_manager_enabled && (var.cert_manager_cluster_issuer == "selfsigned-issuer" || var.cert_manager_cluster_issuer == "cluster-ca-issuer") ? "cluster-ca-issuer" : var.cert_manager_cluster_issuer
}

module "loki" {
  source = "./components/loki"

  env                = var.env
  loki_enabled       = var.loki_enabled
  domain             = var.domain
  dns_service        = var.dns_service
  ingress_class_name = var.ingress_class_name

  # Loki Storage Config
  storage_type         = "s3" # Force S3 backend since we have MinIO or External S3
  s3_bucket_name       = var.s3_bucket_name
  s3_region            = local.s3_region
  s3_access_key_id     = local.s3_access_key
  s3_secret_access_key = local.s3_secret_key
  s3_endpoint          = local.s3_endpoint

  storage_class = var.storage_class
  storage_size  = var.loki_storage_size

  is_loki_distributed = false

  cert_manager_enabled        = var.cert_manager_enabled
  cert_manager_cluster_issuer = local.issuer_name
}

module "mimir" {
  source = "./components/mimir"

  env                = var.env
  mimir_enabled      = var.mimir_enabled
  domain             = var.domain
  dns_service        = var.dns_service
  ingress_class_name = var.ingress_class_name

  s3_access_key = local.s3_access_key
  s3_secret_key = local.s3_secret_key
  s3_endpoint   = local.s3_endpoint

  storage_class = var.storage_class
  storage_size  = var.mimir_storage_size
}

module "tempo" {
  source = "./components/tempo"

  env                = var.env
  tempo_enabled      = var.tempo_enabled
  domain             = var.domain
  dns_service        = var.dns_service
  ingress_class_name = var.ingress_class_name

  s3_access_key = local.s3_access_key
  s3_secret_key = local.s3_secret_key
  s3_endpoint   = local.s3_endpoint

  cert_manager_enabled        = var.cert_manager_enabled
  cert_manager_cluster_issuer = local.issuer_name

  storage_class = var.storage_class
  storage_size  = var.tempo_storage_size
}

module "prometheus" {
  source = "./components/prometheus"

  env                = var.env
  prometheus_enabled = var.prometheus_enabled
  grafana_enabled    = var.grafana_enabled

  domain                 = var.domain
  grafana_admin_password = var.grafana_admin_password
  ingress_class_name     = var.ingress_class_name

  cert_manager_enabled        = var.cert_manager_enabled
  cert_manager_cluster_issuer = local.issuer_name
  mimir_remote_write_url      = var.mimir_enabled ? "http://mimir-gateway.mimir.svc.cluster.local:80/api/v1/push" : ""

  mimir_enabled = var.mimir_enabled
  loki_enabled  = var.loki_enabled
  tempo_enabled = var.tempo_enabled

  storage_class             = var.storage_class
  prometheus_storage_size   = var.prometheus_server_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size
  grafana_storage_size      = var.grafana_storage_size
}

module "alloy" {
  source = "./components/alloy"

  env             = var.env
  alloy_enabled   = var.alloy_enabled
  cluster_engine  = var.cluster_engine
  loki_url        = module.loki.loki_push_url
  skip_namespaces = ["cert-manager", "kube-system", "minio"]
}

module "opentelemetry" {
  source = "./components/opentelemetry"

  env                   = var.env
  opentelemetry_enabled = var.opentelemetry_enabled
  tempo_endpoint        = "tempo-distributor.tempo.svc.cluster.local:4317"

  depends_on = [
    module.cert_manager
  ]
}

module "traefik" {
  source = "./components/traefik"

  traefik_enabled = var.traefik_enabled
}
