variable "env" {
  description = "Environment name (dev, prod) - acts as cluster name"
  type        = string
}

variable "cluster_engine" {
  description = "Cluster engine type (rke2, kind, etc.)"
  type        = string
}

variable "alloy_enabled" {
  description = "Enable Alloy deployment"
  type        = bool
  default     = true
}

variable "alloy_version" {
  description = "Alloy Helm chart version"
  type        = string
  default     = "1.6.0" # Verify actual version
}

variable "loki_url" {
  description = "Full URL to push logs to Loki"
  type        = string
}

variable "skip_namespaces" {
  description = "List of namespaces to skip log collection from"
  type        = list(string)
  default     = ["kube-system", "istio-system"]
}

variable "tempo_endpoint" {
  description = "Tempo GRPC endpoint (host:port)"
  type        = string
  default     = "tempo-distributor.tempo.svc.cluster.local:4317"
}

variable "mimir_url" {
  description = "Mimir remote write URL"
  type        = string
  default     = "http://mimir-gateway.mimir.svc.cluster.local/api/v1/push"
}

variable "loki_enabled" {
  description = "Enable Loki log forwarding"
  type        = bool
  default     = false
}

variable "tempo_enabled" {
  description = "Enable Tempo tracing"
  type        = bool
  default     = false
}

variable "mimir_enabled" {
  description = "Enable Mimir metrics forwarding"
  type        = bool
  default     = false
}
