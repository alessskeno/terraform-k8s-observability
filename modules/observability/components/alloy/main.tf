resource "kubernetes_namespace" "alloy" {
  count = var.alloy_enabled ? 1 : 0
  metadata {
    name = "alloy"
  }
}

resource "helm_release" "alloy" {
  count           = var.alloy_enabled ? 1 : 0
  timeout         = 300
  name            = "alloy"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "alloy"
  namespace       = kubernetes_namespace.alloy[0].metadata[0].name
  atomic          = false
  cleanup_on_fail = true
  max_history     = 10
  version         = var.alloy_version

  values = [
    yamlencode(local.alloy_values)
  ]
}

resource "kubernetes_config_map" "alloy_config" {
  count = var.alloy_enabled ? 1 : 0
  metadata {
    name      = "alloy-config"
    namespace = kubernetes_namespace.alloy[0].metadata[0].name
  }

  data = {
    "config.alloy" = templatefile("${path.module}/templates/config.alloy.tpl", {
      loki_url        = var.loki_url
      cluster_name    = var.env
      cluster_engine  = var.cluster_engine
      skip_namespaces = local.skip_namespaces_str
      tempo_endpoint  = var.tempo_endpoint
      mimir_url       = var.mimir_url
    })
  }
}

locals {
  skip_namespaces_str = join("|", var.skip_namespaces)

  alloy_values = {
    controller = {
      type              = "daemonset"
      priorityClassName = "system-node-critical"
      extraAnnotations = {
        "reloader.stakater.com/auto" = "true"
      }
      volumes = {
        extra = [
          {
            name     = "varlog"
            hostPath = { path = "/var/log" }
          },
          {
            name = "storage"
            hostPath = {
              path = "/var/lib/alloy/data"
              type = "DirectoryOrCreate"
            }
          }
        ]
      }
      tolerations = [
        {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]
    }

    alloy = {
      configMap = {
        create = false
        name   = "alloy-config"
      }
      storagePath     = "/var/lib/alloy/data"
      enableReporting = false

      securityContext = {
        runAsUser              = 0
        runAsGroup             = 0
        privileged             = false
        readOnlyRootFilesystem = true
      }

      mounts = {
        varlog           = false
        dockercontainers = false
        extra = [
          {
            name      = "varlog"
            mountPath = "/var/log"
            readOnly  = true
          },
          {
            name      = "storage"
            mountPath = "/var/lib/alloy/data"
          }
        ]
      }

      extraPorts = [
        { name = "otlp-grpc", port = 4317, targetPort = 4317, protocol = "TCP" },
        { name = "otlp-http", port = 4318, targetPort = 4318, protocol = "TCP" }
      ]

      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    }
  }
}
