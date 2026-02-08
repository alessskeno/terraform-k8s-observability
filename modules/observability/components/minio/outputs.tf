output "endpoint" {
  value = "minio.minio.svc.cluster.local:9000"
}

output "access_key" {
  value = var.access_key
}

output "secret_key" {
  value     = var.secret_key
  sensitive = true
}
