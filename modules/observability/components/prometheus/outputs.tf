output "prometheus_url" {
  description = "Internal URL for Prometheus"
  value       = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
}

output "prometheus_external_url" {
  description = "External URL for Prometheus"
  value       = "https://prometheus-${var.env}.${var.domain}"
}
