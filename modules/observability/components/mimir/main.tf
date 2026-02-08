resource "kubernetes_namespace" "mimir" {
  count = var.mimir_enabled ? 1 : 0
  metadata {
    name = "mimir"
  }
}

resource "helm_release" "mimir" {
  count           = var.mimir_enabled ? 1 : 0
  name            = "mimir"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "mimir-distributed"
  version         = var.mimir_version
  namespace       = kubernetes_namespace.mimir[0].metadata[0].name
  atomic          = false
  cleanup_on_fail = true
  timeout         = 1200

  values = [
    yamlencode(local.mimir_values)
  ]
}

locals {
  mimir_domain = "mimir.${var.domain}"

  mimir_values = {
    global = {
      clusterDomain = "cluster.local"
      dnsService    = var.dns_service
    }

    # HA Configuration: Replicas=3 and disabled affinity for single-node cluster compatibility
    query_scheduler = { replicas = 1, affinity = {} }
    querier         = { replicas = 1, affinity = {} }
    distributor     = { replicas = 1, affinity = {} }
    compactor       = { replicas = 3, affinity = {}, persistentVolume = { storageClass = var.storage_class, size = var.storage_size } }

    alertmanager = {
      replicas         = 3
      affinity         = {}
      persistentVolume = { storageClass = var.storage_class, size = var.storage_size }
    }

    ingester = {
      replicas             = 3
      affinity             = {}
      zoneAwareReplication = { enabled = false }
      persistentVolume     = { storageClass = var.storage_class, size = var.storage_size }
      # Ensure topology spread doesn't block us on 1 node
      topologySpreadConstraints = []
    }
    store_gateway = {
      replicas                  = 3
      affinity                  = {}
      zoneAwareReplication      = { enabled = false }
      persistentVolume          = { storageClass = var.storage_class, size = var.storage_size }
      topologySpreadConstraints = []
    }
    ruler = {
      replicas         = 3
      affinity         = {}
      persistentVolume = { storageClass = var.storage_class, size = var.storage_size }
    }

    minio = {
      enabled = false
    }

    mimir = {
      structuredConfig = {
        limits = {
          max_global_series_per_user        = 1000000
          ingestion_rate                    = 1000000
          ingestion_burst_size              = 2000000
          compactor_blocks_retention_period = "1y"
        }

        # Removed replication_factor=1 overrides to use default (3)

        common = {
          storage = {
            backend = "s3"
            s3 = {
              access_key_id     = var.s3_access_key
              secret_access_key = var.s3_secret_key
              endpoint          = var.s3_endpoint
              bucket_name       = "mimir-ruler"
              insecure          = true
            }
          }
        }
        blocks_storage = {
          s3 = { bucket_name = "mimir-tsdb" }
        }
        alertmanager_storage = {
          s3 = { bucket_name = "mimir-ruler" }
        }
        ruler_storage = {
          s3 = { bucket_name = "mimir-ruler" }
        }
      }
    }

    # Ingress for Mimir (nginx)
    nginx = {
      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class_name
        hosts = [
          {
            host  = local.mimir_domain
            paths = [{ path = "/", pathType = "Prefix" }]
          }
        ]
        tls = [{
          secretName = "mimir-tls"
          hosts      = [local.mimir_domain]
        }]
      }
    }
  }
}
