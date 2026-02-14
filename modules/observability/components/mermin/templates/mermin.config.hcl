log_level = "info"

# 1. Network Interface Discovery (Optimized for RKE2/CNI)
# RKE2 defaults usually involve Calico, Flannel, or Cilium. 
# We capture CNI interfaces to see pod-to-pod traffic.
discovery "instrument" {
  # Default broad capture for complete visibility
  interfaces = [
    "veth*",      # Pod-to-pod 
    "cali*",      # Calico (Common in RKE2/Canal)
    "flannel*",   # Flannel (Common in RKE2/Canal)
    "cilium_*",   # Cilium
    "tunl*",      # IPIP tunnels
    "vxlan*",     # VXLAN overlays
    "lxc*"        # Container interfaces
  ]
}

# 2. Kubernetes Metadata Enrichment
discovery "informer" "k8s" {
  informers_sync_timeout = "60s" # Increased for large clusters (500+ apps)
  
  # Selectors to build in-memory cache for enrichment
  selectors = [
    { kind = "Service" },
    { kind = "Pod" },
    { kind = "ReplicaSet" },
    { kind = "Deployment" },
    { kind = "DaemonSet" },
    { kind = "StatefulSet" },
    { kind = "Node" }
  ]
  
  owner_relations = {
    max_depth = 5
  }
}

# 3. Flow Span Configuration
span {
  max_record_interval = "60s"
  tcp_timeout         = "20s"
  udp_timeout         = "60s"
}

# 4. OTLP Export to Alloy (High-Throughput Tuning)
export "traces" {
  otlp = {
    # REPLACE with your specific Alloy service address
    endpoint = "http://alloy.alloy.svc.cluster.local:4317" 
    
    protocol = "grpc" # gRPC is recommended for performance [7]

    # Tuning for >10k flows/sec [2, 4, 5]
    
    # Larger batches improve efficiency but slightly increase latency
    max_batch_size = 2048 
    
    # Wait up to 2s to fill a batch
    max_batch_interval = "2s" 
    
    # Large queue to handle bursts without dropping spans
    # 65536 is recommended for very high throughput (>10K flows/sec) [4]
    max_queue_size = 65536 
    
    # Increase concurrent exports if Alloy takes time to process
    # 8 is recommended for high-throughput [5]
    max_concurrent_exports = 8 
    
    # Timeout for individual export requests
    timeout = "10s" 
    max_export_timeout = "30s"
  }
}
# 1. Map Source IP -> Kubernetes Metadata (Pod/Service Name)
attributes "source" "k8s" {
  extract {
    metadata = [
      "[*].metadata.name",
      "[*].metadata.namespace",
      "[*].metadata.uid"
    ]
  }

  association {
    pod = {
      sources = [
        # Map Source IP to Pod IP
        { from = "source.ip", to = ["status.podIP", "status.podIPs[*]", "status.hostIP"] },
        # Map Source Port to Container Port
        { from = "source.port", to = ["spec.containers[*].ports[*].containerPort"] }
      ]
    }
    
    service = {
      sources = [
        # Map Source IP to Service ClusterIP/ExternalIP
        { from = "source.ip", to = ["spec.clusterIP", "spec.clusterIPs[*]", "spec.externalIPs[*]"] }
      ]
    }
  }
}

# 2. Map Destination IP -> Kubernetes Metadata
attributes "destination" "k8s" {
  extract {
    metadata = [
      "[*].metadata.name",
      "[*].metadata.namespace",
      "[*].metadata.uid"
    ]
  }

  association {
    pod = {
      sources = [
        { from = "destination.ip", to = ["status.podIP", "status.podIPs[*]", "status.hostIP"] },
        { from = "destination.port", to = ["spec.containers[*].ports[*].containerPort"] }
      ]
    }

    service = {
      sources = [
        { from = "destination.ip", to = ["spec.clusterIP", "spec.clusterIPs[*]", "spec.externalIPs[*]"] }
      ]
    }
  }
}

# 5. Internal Metrics (for monitoring Mermin itself)
internal "metrics" {
  enabled = true
  port    = 10250
  debug_metrics_enabled = false 
}