variable "mermin_enabled" {
  description = "Enable Mermin (eBPF Network Flow Collector)"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace to deploy mermin"
  type        = string
}

variable "mermin_version" {
  description = "Mermin Helm chart version"
  type        = string
  default     = "0.1.0" # Check for the latest version on their GitHub/Helm repo
}

variable "env" {
  type = string
}
