output "loki_endpoint" {
  value = module.loki.loki_endpoint
}

output "prometheus_url" {
  value = "http://prometheus.${var.domain}"
}

output "grafana_url" {
  value = "http://grafana.${var.domain}"
}

output "tempo_endpoint" {
  value = var.tempo_enabled ? "tempo-distributor.tempo.svc.cluster.local:4317" : ""
}
