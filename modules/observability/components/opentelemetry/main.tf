terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

resource "helm_release" "opentelemetry_operator" {
  count           = var.opentelemetry_enabled ? 1 : 0
  name            = "opentelemetry-operator"
  repository      = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart           = "opentelemetry-operator"
  version         = var.opentelemetry_operator_version
  namespace       = var.namespace
  atomic          = false
  cleanup_on_fail = true
  timeout         = 300

  values = [
    yamlencode({
      manager = {
        autoInstrumentation = {
          go = {
            enabled = true
          }
        }
      }
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

# Unified Instrumentation Rules routed to Grafana Alloy
resource "kubectl_manifest" "otel_instrumentation" {
  count = var.opentelemetry_enabled ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "alloy-instrumentation"
      namespace = var.namespace
    }
    spec = {
      # Route ALL telemetry to your Grafana Alloy service
      exporter = {
        endpoint = "http://alloy.${var.namespace}.svc.cluster.local:4317"
      }
      propagators = ["tracecontext", "baggage", "b3"]
      sampler = {
        type     = "parentbased_traceidratio"
        argument = "0.25" # 100% sampling for dev. Lower this for prod (e.g., "0.1")
      }

      # Language-specific optimizations
      python = {
        env = [
          {
            name  = "OTEL_LOGS_EXPORTER"
            value = "none" # Turn off OTel logs if you use Promtail/Alloy for logging
          }
        ]
      }
      dotnet = {
        env = [
          {
            name  = "OTEL_DOTNET_AUTO_TRACES_ADDITIONAL_SOURCES"
            value = "MassTransit,Npgsql,OpenTelemetry.Instrumentation.StackExchangeRedis,MongoDB.Driver.Core.Extensions.DiagnosticSources" # Example: Add extra .NET trace sources
          }
        ]
      }
      go = {
        env = [
          {
            name  = "OTEL_GO_AUTO_INCLUDE_DB_STATEMENT"
            value = "true" # Forces the eBPF agent to capture actual SQL query text
          }
        ]
      }
    }
  })

  validate_schema = false
  depends_on      = [helm_release.opentelemetry_operator]
}
