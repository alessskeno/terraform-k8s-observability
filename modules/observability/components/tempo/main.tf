resource "kubernetes_namespace" "tempo" {
  count = var.tempo_enabled ? 1 : 0
  metadata {
    name = "tempo"
  }
}

resource "helm_release" "tempo" {
  count           = var.tempo_enabled ? 1 : 0
  name            = "tempo"
  repository      = "https://grafana-community.github.io/helm-charts/"
  chart           = "tempo-distributed"
  version         = var.tempo_version
  namespace       = kubernetes_namespace.tempo[0].metadata[0].name
  atomic          = false
  cleanup_on_fail = true
  timeout         = 900
  wait            = false

  values = [
    yamlencode(local.tempo_values)
  ]
}

locals {
  tempo_domain = "tempo.${var.domain}"

  tempo_values = {
    global = {
      clusterDomain = "cluster.local"
      dnsService    = var.dns_service
    }
    gateway = {
      enabled = true
      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class_name
        hosts = [
          {
            host = local.tempo_domain
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        annotations = merge(
          {
            "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
          },
          var.cert_manager_enabled ? {
            "cert-manager.io/cluster-issuer" = var.cert_manager_cluster_issuer
            "cert-manager.io/common-name"    = local.tempo_domain
          } : {}
        )
        tls = [{
          secretName = "tempo-tls"
          hosts      = [local.tempo_domain]
        }]
      }
    }
    metricsGenerator = {
      enabled = true
      config = {
        registry = {
          external_labels = {
            source = "tempo"
          }
        }
        storage = {
          path = "/var/tempo/generator/wal"
          remote_write = [{
            url            = "http://kube-prometheus-stack-prometheus.prometheus.svc.cluster.local:9090/api/v1/write"
            send_exemplars = true
          }]
        }
        traces_storage = {
          path = "/var/tempo/generator/traces"
        }
      }
      persistence = {
        enabled      = true
        size         = var.storage_size
        storageClass = var.storage_class
      }
    }


    # Overrides and Storage from yaml
    overrides = {
      defaults = {
        ingestion = {
          rate_limit_bytes = 15000000
        }
        metrics_generator = {
          processors = ["service-graphs", "span-metrics", "local-blocks"]
        }
      }
    }

    storage = {
      trace = {
        backend = "s3"
        s3 = {
          access_key = var.s3_access_key
          secret_key = var.s3_secret_key
          bucket     = "tempo-traces"
          endpoint   = var.s3_endpoint
          insecure   = true
        }
      }
    }

    minio = {
      enabled = false
    }

    traces = {
      otlp = {
        grpc = { enabled = true }
        http = { enabled = true }
      }
    }

    distributor = {
      config = {
        log_received_spans = {
          enabled = true
        }
      }
    }
  }
}
