
resource "helm_release" "loki" {
  count           = var.loki_enabled ? 1 : 0
  timeout         = 1200
  name            = "loki"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "loki"
  namespace       = var.namespace
  atomic          = false
  cleanup_on_fail = true
  max_history     = 10
  version         = var.loki_version

  values = [
    yamlencode(local.loki_values)
  ]
}

locals {
  loki_domain = "loki-${var.env}.${var.domain}"

  object_store_type = var.storage_type == "s3" ? "s3" : "filesystem"

  loki_values = {
    global = {
      clusterDomain = "cluster.local"
      dnsService    = var.dns_service
    }

    deploymentMode = var.is_loki_distributed ? "Distributed" : "SimpleScalable"

    loki = {
      auth_enabled = false
      schemaConfig = {
        configs = [{
          from         = "2024-08-01"
          store        = "tsdb"
          object_store = local.object_store_type
          schema       = "v13"
          index = {
            prefix = "index_" # Changed from loki_index_
            period = "24h"
          }
          chunks = {
            period = "24h"
          }
        }]
      }
      commonConfig = {
        replication_factor = 1
      }
      storage = {
        bucketNames = {
          chunks = "loki-chunks"
          ruler  = "loki-ruler"
          admin  = "loki-admin"
        }
        type = var.storage_type
        # Using a conditional for s3 vs filesystem inside the object_store config
        s3 = var.storage_type == "s3" ? {
          endpoint         = var.s3_endpoint
          secretAccessKey  = var.s3_secret_access_key
          accessKeyId      = var.s3_access_key_id
          insecure         = true
          s3ForcePathStyle = true
          region           = var.s3_region
        } : null
        filesystem = var.storage_type == "filesystem" ? {
          chunks_directory = "/var/loki/chunks"
          rules_directory  = "/var/loki/rules"
        } : null
      }

      ingester = {
        chunk_encoding = "snappy"
      }
    }

    read = {
      replicas = 1
      persistence = {
        storageClass = var.storage_class
        size         = var.storage_size
      }
    }
    write = {
      replicas = 1
      persistence = {
        storageClass = var.storage_class
        size         = var.storage_size
      }
    }
    backend = {
      replicas = 1
      persistence = {
        storageClass = var.storage_class
        size         = var.storage_size
      }
    }

    # Gateway / Ingress
    gateway = {
      enabled = true
      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class_name
        hosts = [
          {
            host = local.loki_domain
            paths = [{
              path     = "/"
              pathType = "Prefix"
            }]
          }
        ]
        tls = [{
          secretName = "loki-tls" # or cert-manager secret
          hosts      = [local.loki_domain]
        }]
        annotations = merge(
          {
            "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
          },
          var.cert_manager_enabled ? {
            "cert-manager.io/cluster-issuer" = var.cert_manager_cluster_issuer
            "cert-manager.io/common-name"    = local.loki_domain
          } : {}
        )
      }
    }



    minio = {
      enabled = var.storage_type == "filesystem" # Enable embedded MinIO for 'filesystem' experience if desired?
      # Actually, Loki chart documentation says 'filesystem' is valid object_store.
    }
  }
}
