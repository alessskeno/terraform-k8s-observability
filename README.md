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
  source = "github.com/alessskeno/terraform-k8s-observability//modules/observability?ref=v1.0.0"

  # --- Environment & Global Settings ---
  env            = "dev"
  domain         = "example.com"
  cluster_engine = "kind"     # Options: kind, rke2, eks

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
| `env` | Environment name (dev, prod) | `string` | n/a | **Yes** |
| `domain` | Base domain for Ingress | `string` | n/a | **Yes** |
| `cluster_engine` | Cluster type (`kind`, `rke2`) | `string` | `"rke2"` | No |
| `traefik_enabled` | Enable Traefik Ingress | `bool` | `true` | No |
| `minio_enabled` | Enable self-hosted MinIO | `bool` | `true` | No |
| `minio_access_key` | Access Key for MinIO | `string` | n/a | If MinIO enabled |
| `minio_secret_key` | Secret Key for MinIO | `string` | n/a | If MinIO enabled |
| `s3_bucket_name` | Bucket name for object storage | `string` | `""` | If MinIO disabled |
| `grafana_admin_password` | Grafana admin password | `string` | `"admin"` | No |

## Outputs

* `grafana_url`: URL for Grafana dashboard.
* `minio_console_url`: URL for MinIO console (if enabled).

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
