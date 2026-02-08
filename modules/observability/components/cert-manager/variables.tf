variable "cert_manager_enabled" {
  description = "Enable Cert Manager"
  type        = bool
  default     = true
}

variable "domain" {
  description = "Domain name"
  type        = string
}

variable "cert_manager_cluster_issuer" {
  description = "Cert Manager Cluster Issuer"
  type        = string
  default     = "cluster-ca-issuer" # Default to self-signed for plug-and-play
}

variable "cert_manager_version" {
  description = "Cert Manager version"
  type        = string
  default     = "1.14.0"
}
