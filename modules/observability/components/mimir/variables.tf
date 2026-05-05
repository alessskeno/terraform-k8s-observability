variable "env" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy mimir"
  type        = string
}

variable "mimir_enabled" {
  description = "Enable Mimir"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Storage Class for Mimir PV"
  type        = string
  default     = "longhorn"
}

variable "storage_size" {
  description = "Storage Size for Mimir PV"
  type        = string
  default     = "10Gi"
}

variable "mimir_version" {
  description = "Mimir chart version"
  type        = string
  default     = "6.0.5"
}

variable "domain" {
  description = "Domain name"
  type        = string
}

variable "dns_service" {}

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
