variable "env" {
  description = "Environment name"
  type        = string
}

variable "prometheus_enabled" {
  description = "Enable Prometheus"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "grafana_enabled" {
  description = "Enable Grafana"
  type        = bool
  default     = true
}

variable "mimir_enabled" {
  description = "Enable Mimir"
  type        = bool
  default     = false
}

variable "mermin_enabled" {
  description = "Enable Mermin"
  type        = bool
  default     = false
}

variable "loki_enabled" {
  description = "Enable Loki"
  type        = bool
  default     = false
}

variable "tempo_enabled" {
  description = "Enable Tempo"
  type        = bool
  default     = false
}

variable "prometheus_version" {
  description = "Prometheus chart version"
  type        = string
  default     = "81.5.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "domain" {
  description = "Domain name"
  type        = string
}

variable "mimir_remote_write_url" {
  description = "Mimir Remote Write URL"
  type        = string
  default     = ""
}

variable "storage_class" {
  description = "Storage Class for Prometheus PV"
  type        = string
  default     = "longhorn"
}

variable "prometheus_storage_size" {
  description = "Storage Size for Prometheus Server PV"
  type        = string
  default     = "5Gi"
}

variable "grafana_storage_size" {
  description = "Storage Size for Grafana PV"
  type        = string
  default     = "10Gi"
}

variable "alertmanager_storage_size" {
  description = "Storage Size for Alertmanager PV"
  type        = string
  default     = "10Gi"
}

variable "cert_manager_enabled" {
  description = "Enable cert-manager integration"
  type        = bool
  default     = false
}

variable "cert_manager_cluster_issuer" {
  description = "Cluster Issuer for cert-manager"
  type        = string
}
