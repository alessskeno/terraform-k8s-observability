variable "env" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "loki_enabled" {
  description = "Enable Loki deployment"
  type        = bool
  default     = true
}

variable "loki_version" {
  description = "Loki Helm chart version"
  type        = string
  default     = "6.52.0" # Example default, should match user's version if possible
}

variable "is_loki_distributed" {
  description = "Deploy Loki in Distributed mode"
  type        = bool
  default     = false
}

variable "domain" {
  description = "Base domain for Ingress"
  type        = string
}

variable "dns_service" {
  description = "DNS service for Loki Ingress"
  type        = string
  default     = ""
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., nginx, traefik)"
  type        = string
  default     = "nginx"
}

variable "domain_crt" {
  description = "TLS Certificate (Base64)"
  type        = string
  default     = ""
}

variable "domain_key" {
  description = "TLS Key (Base64)"
  type        = string
  default     = ""
}

variable "cert_manager_enabled" {
  description = "Enable Cert Manager integration"
  type        = bool
  default     = true
}

variable "cert_manager_cluster_issuer" {
  description = "ClusterIssuer for Ingress"
  type        = string
  default     = "cluster-ca-issuer"
}

variable "storage_class" {
  description = "Storage Class for Loki PV"
  type        = string
  default     = "standard"
}

variable "storage_size" {
  description = "Storage Size for Loki PV"
  type        = string
  default     = "3Gi"
}

# Storage Configuration
variable "storage_type" {
  description = "Storage backend type: 's3' or 'filesystem'"
  type        = string
  default     = "filesystem"
  validation {
    condition     = contains(["s3", "filesystem"], var.storage_type)
    error_message = "Storage type must be 's3' or 'filesystem'."
  }
}

variable "s3_access_key_id" {
  description = "S3 Access Key"
  type        = string
  default     = ""
}

variable "s3_secret_access_key" {
  description = "S3 Secret Key"
  type        = string
  default     = ""
}

variable "s3_endpoint" {
  description = "S3 Endpoint"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 Bucket Name"
  type        = string
  default     = ""
}

variable "s3_region" {
  description = "S3 Region"
  type        = string
  default     = "us-east-1"
}
