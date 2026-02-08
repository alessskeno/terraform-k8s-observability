// -----------------------------------------------------------------------------
// 1. FORWARDING: Push to Loki
// -----------------------------------------------------------------------------
loki.write "loki_endpoint" {
  endpoint {
    url = "${loki_url}"
  }
}

// -----------------------------------------------------------------------------
// 2. DISCOVERY: Kubernetes Pods
// -----------------------------------------------------------------------------
discovery.kubernetes "pods" {
  role = "pod"
  selectors {
    role  = "pod"
    field = "spec.nodeName=" + coalesce(sys.env("HOSTNAME"), constants.hostname)
  }
}

discovery.relabel "pod_logs" {
  targets = discovery.kubernetes.pods.targets

  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    action = "drop"
    regex = "^(istio-proxy|istio-init)$"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    action = "drop"
    regex = "^(${skip_namespaces})$"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_controller_name"]
    regex = "([0-9a-z-.]+?)(-[0-9a-f]{8,10})?"
    action = "replace"
    target_label = "__tmp_controller_name"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    target_label  = "app"
    separator     = "/"
    action        = "replace"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
    target_label  = "job"
    separator     = "/"
    action        = "replace"
  }

  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label  = "namespace"
    action        = "replace"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    target_label = "node"
    action        = "replace"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
    action        = "replace"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label  = "container"
    action        = "replace"
  }
}

loki.source.kubernetes "pod_logs" {
  targets    = discovery.relabel.pod_logs.output
  forward_to = [loki.process.aggregator.receiver]
}


// -----------------------------------------------------------------------------
// 3. LOG SOURCE: Node System Logs
// -----------------------------------------------------------------------------
local.file_match "node_system_logs" {
  path_targets = [
    { "__path__" = "/var/log/syslog", "job" = "node/syslog" },
    { "__path__" = "/var/log/auth.log", "job" = "node/authlog" },
    { "__path__" = "/var/log/kern.log", "job" = "node/kernlog" },
  ]
}

discovery.relabel "node_logs" {
  targets = local.file_match.node_system_logs.targets

  rule {
    target_label = "node"
    replacement  = coalesce(sys.env("HOSTNAME"), constants.hostname)
  }
}

loki.source.file "node_system_logs" {
  targets    = discovery.relabel.node_logs.output
  forward_to = [loki.process.aggregator.receiver]
}


// -----------------------------------------------------------------------------
// 4. LOG SOURCE: Node Journal Logs
// -----------------------------------------------------------------------------
%{ if cluster_engine == "rke2" }
loki.source.journal "rke2_agent" {
  labels = {
    "job"     = "node/journal",
    "cluster" = "${cluster_name}",
    "node"    = coalesce(sys.env("HOSTNAME"), constants.hostname),
    "unit"    = "rke2-agent",
  }
  matches    = "_SYSTEMD_UNIT=rke2-agent.service"
  forward_to = [loki.process.aggregator.receiver]
}

loki.source.journal "rke2_server" {
  labels = {
    "job"     = "node/journal",
    "cluster" = "${cluster_name}",
    "node"    = coalesce(sys.env("HOSTNAME"), constants.hostname),
    "unit"    = "rke2-server",
  }
  matches    = "_SYSTEMD_UNIT=rke2-server.service"
  forward_to = [loki.process.aggregator.receiver]
}
%{ endif }

// -----------------------------------------------------------------------------
// 5. PROCESSING & MULTILINE
// -----------------------------------------------------------------------------
loki.process "aggregator" {
  stage.multiline {
    firstline = "^(\\[)?(20|19)\\d{2}[-/.](0[1-9]|1[0-2])[-/.](0[1-9]|[12][0-9]|3[01])"
  }

  stage.static_labels {
    values = {
      "cluster" = "${cluster_name}",
      "collector" = "alloy",
    }
  }

  forward_to = [loki.write.loki_endpoint.receiver]
}

// -----------------------------------------------------------------------------
// 6. FUTURE PROOF: OpenTelemetry Receiver
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// 6. TRACING & METRICS: Receive OTLP
// -----------------------------------------------------------------------------
otelcol.receiver.otlp "default" {
  grpc { endpoint = "0.0.0.0:4317" }
  http { endpoint = "0.0.0.0:4318" }

  output {
    traces  = [otelcol.processor.batch.default.input]
    metrics = [otelcol.processor.batch.default.input]
  }
}

otelcol.processor.batch "default" {
  output {
    traces  = [otelcol.exporter.otlp.tempo.input]
    metrics = [otelcol.exporter.prometheus.mimir.input]
  }
}

// -----------------------------------------------------------------------------
// 7. EXPORTERS
// -----------------------------------------------------------------------------
otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "${tempo_endpoint}"
    tls {
      insecure = true
    }
  }
}

otelcol.exporter.prometheus "mimir" {
  forward_to = [prometheus.remote_write.mimir.receiver]
}

prometheus.remote_write "mimir" {
  endpoint {
    url = "${mimir_url}"
  }
}
