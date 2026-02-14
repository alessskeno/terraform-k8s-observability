# Terraform Kubernetes Observability Module

A comprehensive, modular Terraform solution for deploying a full observability stack on Kubernetes. This module integrates best-in-class tools for monitoring, logging, and tracing, designed for ease of use with Kind, RKE2, EKS, or GKE.

## Features

* **Ingress Controller**: Traefik (v3) with configurable NodePort/LoadBalancer.
* **Metrics**: Prometheus (kube-prometheus-stack) & Mimir (optional).
* **Logs**: Grafana Alloy and Loki (scalable log aggregation).
* **Traces**: Tempo (distributed tracing) & OpenTelemetry.
* **Visualization**: Grafana (pre-configured datasources).
* **Storage**: MinIO (self-hosted S3-compatible) or External S3 (AWS/GCP).
* **Security**: Cert-Manager for TLS management.

## Directory Structure

```text
/
├── modules/
│   └── observability/   # Core module (The product)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── components/  # Internal sub-modules (Loki, Tempo, etc.)
│           ├── alloy/
│           ├── minio/
│           ├── mimir/
│           ├── opentelemetry/
│           ├── mermin/
│           ├── loki/
│           ├── tempo/
│           ├── prometheus/
│           ├── grafana/
│           ├── traefik/
│           └── cert-manager/
├── examples/
│   └── simple-kind/     # Ready-to-run example for Kind clusters
└── README.md            # This documentation
```

## Usage

You can use this module directly from GitHub without cloning the repository. Add the following block to your `main.tf`.

### 1. Create `main.tf`

```hcl
module "observability" {
  source = "github.com/alessskeno/terraform-k8s-observability//modules/observability?ref=v1.0.1"

  # --- Environment & Global Settings ---
  env            = "dev"
  domain         = "example.com"
  cluster_engine = "kind"     # Options: kind, rke2, eks
  storage_class  = "standard" # Required: Storage Class for PVCs
  # --- Ingress ---
  traefik_enabled    = true
  ingress_class_name = "traefik"

  # --- Storage (MinIO or S3) ---
  minio_enabled    = true
  minio_access_key = var.minio_access_key
  minio_secret_key = var.minio_secret_key

  # --- Features (Toggle as needed) ---
  prometheus_enabled    = true
  grafana_enabled       = true
  loki_enabled          = true
  tempo_enabled         = true
  mermin_enabled        = true
  cert_manager_enabled  = true

  # --- Security ---
  grafana_admin_password = var.grafana_admin_password
}
```

### 2. Configure Providers (`providers.tf`)

You must configure the Kubernetes and Helm providers to talk to your cluster.

```hcl
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-dev-cluster" # Change this to your context
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-dev-cluster"
  }
}
```

### 3. Deploy

```bash
terraform init
terraform apply
```

## Inputs


| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `env` | Environment name (e.g., dev, prod) | `string` | n/a | **Yes** |
| `domain` | Base domain for Ingress resources | `string` | n/a | **Yes** |
| `cluster_engine` | Cluster engine type (`rke2`, `kind`, etc.) | `string` | `"rke2"` | No |
| `storage_class` | Storage Class for PVCs | `string` | n/a | **Yes** |
| `dns_service` | DNS Service address (e.g., coredns) | `string` | `"rke2-coredns..."` | No |
| `ingress_class_name` | Ingress class name | `string` | `"traefik"` | No |
| **Feature Toggles** | | | | |
| `traefik_enabled` | Enable Traefik Ingress Controller | `bool` | `true` | No |
| `cert_manager_enabled` | Enable Cert-Manager | `bool` | `true` | No |
| `minio_enabled` | Enable self-hosted MinIO | `bool` | `true` | No |
| `prometheus_enabled` | Enable Prometheus Stack | `bool` | `true` | No |
| `grafana_enabled` | Enable Grafana | `bool` | `true` | No |
| `loki_enabled` | Enable Loki (Logs) | `bool` | `true` | No |
| `tempo_enabled` | Enable Tempo (Tracing) | `bool` | `true` | No |
| `mimir_enabled` | Enable Mimir (Long-term Metrics) | `bool` | `true` | No |
| `alloy_enabled` | Enable Grafana Alloy (Collector) | `bool` | `true` | No |
| `opentelemetry_enabled` | Enable OpenTelemetry Operator | `bool` | `true` | No |
| `mermin_enabled` | Enable Mermin (Network Observability) | `bool` | `true` | No |
| **Storage & Secrets** | | | | |
| `minio_access_key` | MinIO Root User | `string` | `"admin"` | No |
| `minio_secret_key` | MinIO Root Password | `string` | `"password"` | No |
| `s3_bucket_name` | AWS S3 Bucket Name (if MinIO disabled) | `string` | `""` | No |
| `s3_region` | AWS S3 Region | `string` | `"us-east-1"` | No |
| `s3_access_key` | AWS S3 Access Key | `string` | `""` | No |
| `s3_secret_key` | AWS S3 Secret Key | `string` | `""` | No |
| `s3_endpoint` | Custom S3 Endpoint | `string` | `""` | No |
| `grafana_admin_password` | Grafana Admin Password | `string` | `"admin"` | No |
| `cert_manager_cluster_issuer` | Cluster Issuer Name | `string` | `"cluster-ca-issuer"` | No |
| **Storage Sizes** | | | | |
| `minio_storage_size` | PVC Size for MinIO | `string` | `"3Gi"` | No |
| `loki_storage_size` | PVC Size for Loki | `string` | `"3Gi"` | No |
| `tempo_storage_size` | PVC Size for Tempo | `string` | `"10Gi"` | No |
| `mimir_storage_size` | PVC Size for Mimir | `string` | `"10Gi"` | No |
| `prometheus_server_storage_size` | PVC Size for Prometheus Server | `string` | `"5Gi"` | No |
| `alertmanager_storage_size` | PVC Size for Alertmanager | `string` | `"10Gi"` | No |
| `grafana_storage_size` | PVC Size for Grafana | `string` | `"10Gi"` | No |

## Outputs

* `grafana_url`: URL for Grafana dashboard.
* `prometheus_url`: URL for Prometheus dashboard.


## Development

To contribute or test locally:

1.  Clone the repository:
    ```bash
    git clone github.com/alessskeno/terraform-k8s-observability.git
    ```
2.  Navigate to the example:
    ```bash
    cd examples/simple-kind
    ```
3.  Initialize and apply:
    ```bash
    terraform init
    terraform apply
    ```

## License

MIT
