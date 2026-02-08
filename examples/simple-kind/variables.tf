variable "kubernetes_cluster" {
  type        = string
  description = "The name/host of the Kubernetes cluster (e.g., https://127.0.0.1:6443)"
}

variable "kubernetes_cluster_ca" {
  type        = string
  description = "The CA certificate of the Kubernetes cluster (base64 encoded)"
}

variable "kubernetes_cluster_cert" {
  type        = string
  description = "The client certificate of the Kubernetes cluster (base64 encoded)"
}
variable "kubernetes_cluster_key" {
  type        = string
  description = "The client key of the Kubernetes cluster (base64 encoded)"
}

variable "domain" {
  type        = string
  description = "Base domain for Ingress resources (e.g., example.com)"
}

variable "grafana_admin_password" {
  description = "Password for Grafana admin"
  type        = string
  sensitive   = true
}

# MinIO Credentials
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

# External S3 (Optional)
variable "s3_access_key" {
  type        = string
  description = "External S3 Access Key"
  default     = ""
}

variable "s3_secret_key" {
  type        = string
  description = "External S3 Secret Key"
  default     = ""
  sensitive   = true
}

variable "s3_endpoint" {
  type        = string
  description = "External S3 Endpoint"
  default     = ""
}

variable "s3_bucket_name" {
  type        = string
  description = "External S3 Bucket Name prefix"
  default     = ""
}

variable "s3_region" {
  type        = string
  description = "External S3 Region"
  default     = "us-east-1"
}
