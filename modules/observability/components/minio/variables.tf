variable "minio_enabled" {
  description = "Enable MinIO"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace to deploy minio"
  type        = string
}

variable "minio_version" {
  description = "MinIO Chart Version"
  type        = string
  default     = "5.4.0" # Official Chart Version
}

variable "tempo_enabled" {
  description = "Enable Tempo Buckets"
  type        = bool
  default     = false
}

variable "loki_enabled" {
  description = "Enable Loki Buckets"
  type        = bool
  default     = false
}

variable "mimir_enabled" {
  description = "Enable Mimir Buckets"
  type        = bool
  default     = false
}

variable "access_key" {
  description = "MinIO Root User"
  type        = string
  default     = "admin"
}

variable "secret_key" {
  description = "MinIO Root Password"
  type        = string
  sensitive   = true
  default     = "password"
}

variable "storage_class" {
  description = "Storage Class for MinIO PV"
  type        = string
  default     = "longhorn"
}

variable "storage_size" {
  description = "Storage Size for MinIO PV"
  type        = string
  default     = "3Gi"
}
