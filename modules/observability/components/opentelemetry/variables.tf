variable "env" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy opentelemetry"
  type        = string
}

variable "opentelemetry_enabled" {
  description = "Enable OpenTelemetry"
  type        = bool
  default     = true
}

variable "opentelemetry_operator_version" {
  description = "OpenTelemetry Operator Helm Version"
  type        = string
  default     = "0.105.0"
}

variable "tempo_endpoint" {
  description = "Tempo Distributor Endpoint"
  type        = string
  default     = "tempo-distributor.tempo.svc.cluster.local:4317"
}
