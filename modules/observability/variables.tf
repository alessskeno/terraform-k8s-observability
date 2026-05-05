variable "env" {}
variable "domain" {}
variable "loki_enabled" { default = true }
variable "prometheus_enabled" { default = true }
variable "grafana_enabled" { default = true }
variable "alloy_enabled" { default = true }
variable "mimir_enabled" { default = true }
variable "tempo_enabled" { default = true }
variable "opentelemetry_enabled" { default = true }
variable "mermin_enabled" { default = true }


variable "cluster_engine" {
  description = "Cluster engine type (rke2, kind, etc.)"
  type        = string
  default     = "rke2"
}

variable "skip_namespaces" {
  description = "Namespaces to skip in Alloy logs collection"
  type        = list(string)
  default     = ["cert-manager", "kube-system", "minio"]
}

variable "dns_service" {
  description = "DNS Service address (e.g., rke2-coredns-rke2-coredns or kube-dns.kube-system.svc.cluster.local)"
  type        = string
  default     = "rke2-coredns-rke2-coredns"
}

variable "traefik_enabled" {
  description = "Enable Traefik Ingress Controller"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name for all modules"
  type        = string
  default     = "traefik"
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
  default   = "admin"
}

variable "s3_access_key" { default = "" }
variable "s3_secret_key" { default = "" }
variable "s3_endpoint" { default = "" }
variable "s3_region" { default = "us-east-1" }
variable "s3_bucket_name" { default = "" }


variable "cert_manager_enabled" { default = true }
variable "cert_manager_cluster_issuer" { default = "cluster-ca-issuer" }

variable "minio_enabled" {
  description = "Enable MinIO"
  type        = bool
  default     = true
}

variable "minio_access_key" {
  description = "MinIO Root User"
  type        = string
  default     = "admin"
}

variable "minio_secret_key" {
  description = "MinIO Root Password"
  type        = string
  sensitive   = true
  default     = "password"
}

# ==============================================================================
# Storage Configuration
# ==============================================================================

variable "storage_class" { type = string }

# MinIO
variable "minio_storage_size" { default = "3Gi" }

# Loki
variable "loki_storage_size" { default = "3Gi" }

# Tempo
variable "tempo_storage_size" { default = "10Gi" }

# Prometheus
variable "prometheus_server_storage_size" { default = "5Gi" }
variable "alertmanager_storage_size" { default = "10Gi" }
variable "grafana_storage_size" { default = "10Gi" }

# Mimir
variable "mimir_storage_size" { default = "10Gi" }

# ==============================================================================
# Component Versions
# ==============================================================================

variable "alloy_version" { default = "1.6.0" }
variable "cert_manager_version" { default = "1.14.0" }
variable "loki_version" { default = "6.52.0" }
variable "mermin_version" { default = "0.1.0" }
variable "mimir_version" { default = "6.0.5" }
variable "minio_version" { default = "5.4.0" }
variable "opentelemetry_operator_version" { default = "0.105.0" }
variable "prometheus_version" { default = "81.5.0" }
variable "tempo_version" { default = "2.0.0" }
variable "traefik_version" { default = "39.0.0" }
