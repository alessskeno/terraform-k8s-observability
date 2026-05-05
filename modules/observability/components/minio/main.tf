locals {
  # Conditional bucket creation
  tempo_buckets = var.tempo_enabled ? ["tempo-traces"] : []
  loki_buckets  = var.loki_enabled ? ["loki-chunks", "loki-ruler", "loki-admin"] : []
  mimir_buckets = var.mimir_enabled ? ["mimir-ruler", "mimir-tsdb"] : []

  all_buckets = concat(local.tempo_buckets, local.loki_buckets, local.mimir_buckets)

  # Official MinIO Chart expects a list of maps for buckets
  buckets_config = [
    for bucket in local.all_buckets : {
      name   = bucket
      policy = "none"
      purge  = false
    }
  ]
}

resource "helm_release" "minio" {
  count      = var.minio_enabled ? 1 : 0
  name       = "minio"
  repository = "https://charts.min.io/"
  chart      = "minio"
  version    = var.minio_version
  namespace  = var.namespace
  atomic     = false
  wait       = false

  values = [
    yamlencode({
      rootUser     = var.access_key
      rootPassword = var.secret_key
      replicas     = 3

      buckets = local.buckets_config

      persistence = {
        enabled      = true
        storageClass = var.storage_class
        size         = var.storage_size
      }
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "100m"
        }
      }
      service = {
        type = "ClusterIP"
      }
    })
  ]
}
