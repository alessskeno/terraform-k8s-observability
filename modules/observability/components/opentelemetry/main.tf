terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

resource "kubernetes_namespace" "opentelemetry" {
  count = var.opentelemetry_enabled ? 1 : 0
  metadata {
    name = "opentelemetry-operator-system"
  }
}



resource "helm_release" "opentelemetry_operator" {
  count           = var.opentelemetry_enabled ? 1 : 0
  name            = "opentelemetry-operator"
  repository      = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart           = "opentelemetry-operator"
  version         = var.opentelemetry_operator_version
  namespace       = kubernetes_namespace.opentelemetry[0].metadata[0].name
  atomic          = false
  cleanup_on_fail = true
  timeout         = 300

  values = [
    yamlencode({
      admissionWebhooks = {
        certManager = {
          enabled = true
          issuerRef = {
            kind = "ClusterIssuer"
            name = "cluster-ca-issuer"
          }
        }
      }
    })
  ]
}


# Apply Collector Configuration
resource "kubectl_manifest" "otel_collector" {
  count = var.opentelemetry_enabled ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "apps-telemetry"
      namespace = kubernetes_namespace.opentelemetry[0].metadata[0].name
    }
    spec = {
      mode = "deployment"
      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {}
              http = {}
            }
          }
        }
        processors = {
          batch = {}
        }
        exporters = {
          otlp = {
            endpoint = var.tempo_endpoint
            tls = {
              insecure = true
            }
          }
        }
        service = {
          pipelines = {
            traces = {
              receivers  = ["otlp"]
              processors = ["batch"]
              exporters  = ["otlp"]
            }
          }
        }
      }
    }
  })
  validate_schema = false
  depends_on      = [helm_release.opentelemetry_operator]
}

resource "kubectl_manifest" "otel_instrumentation" {
  count = var.opentelemetry_enabled ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "my-instrumentation"
      namespace = kubernetes_namespace.opentelemetry[0].metadata[0].name
    }
    spec = {
      exporter = {
        endpoint = "http://apps-telemetry-collector.${kubernetes_namespace.opentelemetry[0].metadata[0].name}.svc.cluster.local:4317"
      }
      propagators = [
        "tracecontext",
        "baggage",
        "b3"
      ]
      sampler = {
        type     = "parentbased_traceidratio"
        argument = "0.25"
      }
      python = {
        env = [
          {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://apps-telemetry-collector.${kubernetes_namespace.opentelemetry[0].metadata[0].name}.svc.cluster.local:4318"
          }
        ]
      }
    }
  })

  validate_schema = false
  depends_on      = [helm_release.opentelemetry_operator]
}
