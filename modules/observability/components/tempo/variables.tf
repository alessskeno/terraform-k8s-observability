variable "env" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy tempo"
  type        = string
}

variable "tempo_enabled" {
  description = "Enable Tempo"
  type        = bool
  default     = true
}

variable "tempo_version" {
  description = "Tempo chart version"
  type        = string
  default     = "2.0.0"
}

variable "domain" {
  description = "Domain name"
  type        = string
}

variable "dns_service" {
  description = "DNS Service name for Tempo"
  type        = string
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "s3_access_key" {
  description = "S3 Access Key"
  type        = string
  default     = ""
}

variable "s3_secret_key" {
  description = "S3 Secret Key"
  type        = string
  default     = ""
}

variable "s3_endpoint" {
  description = "S3 Endpoint"
  type        = string
  default     = "tempo-minio.tempo.svc.cluster.local:9000"
}

variable "storage_class" {
  description = "Storage Class for Tempo PV"
  type        = string
  default     = "longhorn"
}

variable "storage_size" {
  description = "Storage Size for Tempo PV"
  type        = string
  default     = "10Gi"
}

variable "cert_manager_enabled" {
  description = "Use cert-manager"
  type        = bool
  default     = false
}

variable "cert_manager_cluster_issuer" {
  description = "Cert-manager cluster issuer"
  type        = string
}
