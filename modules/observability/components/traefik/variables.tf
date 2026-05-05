variable "traefik_enabled" {
  description = "Enable Traefik Ingress Controller"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace to deploy traefik"
  type        = string
}

variable "traefik_version" {
  description = "Traefik Helm Chart Version"
  type        = string
  default     = "39.0.0"
}
