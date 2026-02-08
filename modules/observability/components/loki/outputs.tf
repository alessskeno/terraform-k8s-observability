output "loki_endpoint" {
  description = "Internal service endpoint for Loki (for Alloy/Grafana)"
  value       = "http://loki-gateway.loki.svc.cluster.local"
}

output "loki_push_url" {
  description = "Full push URL for Alloy"
  value       = "http://loki-gateway.loki.svc.cluster.local/loki/api/v1/push"
}
