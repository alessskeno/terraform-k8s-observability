resource "kubernetes_namespace" "prometheus" {
  count = var.prometheus_enabled ? 1 : 0
  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  count           = var.prometheus_enabled ? 1 : 0
  name            = "kube-prometheus-stack"
  repository      = "https://prometheus-community.github.io/helm-charts"
  chart           = "kube-prometheus-stack"
  version         = var.prometheus_version
  namespace       = kubernetes_namespace.prometheus[0].metadata[0].name
  atomic          = false
  cleanup_on_fail = true
  timeout         = 1200

  values = [
    yamlencode(local.prometheus_values)
  ]
}

data "http" "mermin_dashboard" {
  count = var.mermin_enabled ? 1 : 0
  url   = "https://raw.githubusercontent.com/elastiflow/mermin/main/docs/internal-monitoring/grafana-mermin-app.json"
}

resource "kubernetes_config_map" "mermin_dashboard" {
  count = var.mermin_enabled ? 1 : 0

  metadata {
    name      = "mermin-grafana-dashboard"
    namespace = kubernetes_namespace.prometheus[0].metadata[0].name

    labels = {
      grafana_dashboard = "1"
      app               = "mermin"
    }
  }

  data = {
    "mermin-app.json" = data.http.mermin_dashboard[0].response_body
  }
}

locals {
  prometheus_domain = "prometheus-${var.env}.${var.domain}"

  ingress_annotations_prometheus = merge(
    {
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
    },
    var.cert_manager_enabled ? {
      "cert-manager.io/cluster-issuer"       = var.cert_manager_cluster_issuer
      "cert-manager.io/common-name"          = local.prometheus_domain
      "cert-manager.io/subject-organization" = var.domain
    } : {}
  )

  ingress_annotations_grafana = merge(
    {
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
    },
    var.cert_manager_enabled ? {
      "cert-manager.io/cluster-issuer"       = var.cert_manager_cluster_issuer
      "cert-manager.io/common-name"          = local.grafana_domain
      "cert-manager.io/subject-organization" = var.domain
    } : {}
  )

  grafana_domain = "grafana-${var.env}.${var.domain}"

  prometheus_values = {
    defaultRules = {
      rules = {
        windows = false
      }
    }

    prometheus-windows-exporter = {
      prometheus = {
        monitor = {
          enabled = false
        }
      }
    }

    alertmanager = {
      # Add Alertmanager config here if needed
      enabled = true
    }

    prometheus = {
      prometheusSpec = {
        enableRemoteWriteReceiver = true
        enableFeatures            = ["remote-write-receiver"]

        # Remote Write to Mimir as per yaml
        # User said "change mimir endpoints to prometheus for now" but here it explicitly pushes TO Mimir.
        # If Mimir is down, this might err. But we'll follow the file config provided.
        # Remote Write to Mimir if URL provided
        remoteWrite = var.mimir_remote_write_url != "" ? [{
          url = var.mimir_remote_write_url
        }] : []

        retention     = "7d"   # for future use 14d +
        retentionSize = "10GB" # for future use 20GB +

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.prometheus_storage_size
                }
              }
              storageClassName = var.storage_class
            }
          }
        }

        ingress = {
          enabled          = true
          annotations      = local.ingress_annotations_prometheus
          hosts            = [local.prometheus_domain]
          ingressClassName = var.ingress_class_name
          tls = [{
            secretName = "prometheus-tls"
            hosts      = [local.prometheus_domain]
          }]
        }
      }
    }

    grafana = {
      enabled       = var.grafana_enabled
      adminPassword = var.grafana_admin_password

      initChownData = {
        enabled = false
      }
      additionalDataSources = concat(
        var.tempo_enabled ? [{
          name       = "Tempo"
          type       = "tempo"
          access     = "proxy"
          orgId      = 1
          url        = "http://tempo-gateway.tempo.svc.cluster.local"
          basicAuth  = false
          version    = 1
          editable   = true
          apiVersion = 1
          uid        = "tempo"
          jsonData = {
            serviceMap = {
              datasourceUid = "mimir" # Linking to Mimir for service graph
            }
          }
        }] : [],
        var.loki_enabled ? [{
          name     = "Loki"
          type     = "loki"
          access   = "proxy"
          url      = "http://loki-gateway.loki.svc.cluster.local"
          editable = true
          jsonData = {
            maxLines = 1000
          }
        }] : [],
        var.mimir_enabled ? [{
          name      = "Mimir"
          type      = "prometheus"
          uid       = "mimir"
          url       = "http://mimir-gateway.mimir.svc.cluster.local/prometheus"
          access    = "proxy"
          isDefault = false
          jsonData = {
            timeInterval = "30s"
          }
        }] : []
      )

      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class_name
        hosts            = [local.grafana_domain]
        annotations      = local.ingress_annotations_grafana
        tls = [{
          secretName = "grafana-tls"
          hosts      = [local.grafana_domain]
        }]
      }

      persistence = {
        enabled          = true
        size             = var.grafana_storage_size
        storageClassName = var.storage_class
      }
    }
  }
}
