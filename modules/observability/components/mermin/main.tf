resource "kubernetes_namespace" "mermin" {
  count = var.mermin_enabled ? 1 : 0
  metadata {
    name = "mermin"
  }
}

resource "helm_release" "mermin" {
  count           = var.mermin_enabled ? 1 : 0
  name            = "mermin"
  repository      = "https://elastiflow.github.io/mermin"
  chart           = "mermin"
  namespace       = kubernetes_namespace.mermin[0].metadata[0].name
  atomic          = false
  cleanup_on_fail = true
  timeout         = 300

  values = [
    yamlencode({
      resources = {
        requests = {
          cpu    = var.env == "dev" ? "100m" : "1"
          memory = var.env == "dev" ? "128Mi" : "512Mi"
        }
        limits = {
          cpu    = var.env == "dev" ? "500m" : "2"
          memory = var.env == "dev" ? "256Mi" : "1Gi"
        }
      }
      config = {
        restartOnConfigChange = true
        hostPidEnrichment     = true
        content               = file("${path.module}/templates/mermin.config.hcl")
      }
      securityContext = {
        privileged = true
      }
      updateStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxUnavailable = 1
        }
      }
      extraObjects = [
        {
          apiVersion = "monitoring.coreos.com/v1"
          kind       = "PodMonitor"
          metadata = {
            name = "mermin-monitor"
            labels = {
              # MUST match the 'prometheus' release name in your cluster
              release = "kube-prometheus-stack"
            }
          }
          spec = {
            jobLabel = "app.kubernetes.io/name"
            selector = {
              matchLabels = {
                "app.kubernetes.io/name" = "mermin"
              }
            }
            podMetricsEndpoints = [
              {
                port     = "metrics"
                path     = "/metrics"
                interval = "30s"
              }
            ]
            namespaceSelector = {
              matchNames = ["mermin"]
            }
        } }
      ]
  })]
}

data "http" "mermin_dashboard" {
  count = var.mermin_enabled ? 1 : 0
  url   = "https://raw.githubusercontent.com/elastiflow/mermin/main/docs/internal-monitoring/grafana-mermin-app.json"
}
