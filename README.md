# Terraform Kubernetes Observability Module

A comprehensive, modular Terraform solution for deploying a full observability stack on Kubernetes. This module integrates best-in-class tools for monitoring, logging, and tracing, designed for ease of use with Kind, RKE2, or EKS/GKE.

## Features

*   **Ingress Controller**: Traefik (v3) with configurable NodePort/LoadBalancer.
*   **Metrics**: Prometheus (kube-prometheus-stack) & Mimir (optional).
*   **Logs**: Grafana Alloy and Loki (scalable log aggregation).
*   **Traces**: Tempo (distributed tracing) & OpenTelemetry.
*   **Visualization**: Grafana (pre-configured datasources).
*   **Storage**: MinIO (self-hosted S3-compatible) or External S3 (AWS/GCP).
*   **Security**: Cert-Manager for TLS management.

## Directory Structure

```
/
├── modules/
│   └── observability/   # Core module source code
├── examples/
│   └── simple-kind/     # Ready-to-run example for Kind clusters
└── README.md            # This documentation
```

## Quick Start

### Prerequisites
*   Terraform >= 1.0
*   Kubernetes Cluster (Kind, RKE2, EKS, etc.)
*   `kubectl` configured

### 1. clone the repository
```bash
git clone https://github.com/your-username/terraform-k8s-observability.git
cd terraform-k8s-observability
```

### 2. Configure the Example
Navigate to the example directory:
```bash
cd examples/simple-kind
```

Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your cluster details. You need to provide the base64 encoded cluster certificate, key, and CA. You can extract these from your `~/.kube/config` or use the provided script (if applicable).

### 3. Deploy
```bash
terraform init
terraform apply
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `env` | Environment name (dev, prod) | `string` | n/a | yes |
| `domain` | Base domain for Ingress | `string` | n/a | yes |
| `cluster_engine` | Cluster type (`kind`, `rke2`) | `string` | `"rke2"` | no |
| `traefik_enabled` | Enable Traefik Ingress | `bool` | `true` | no |
| `ingress_class_name` | Ingress class name | `string` | `"traefik"` | no |
| `minio_enabled` | Enable self-hosted MinIO | `bool` | `true` | no |
| `s3_bucket_name` | Bucket name for object storage | `string` | `""` | if minio disabled |
| `grafana_admin_password` | Grafana admin password | `string` | `"admin"` | no |

## Outputs

*   `grafana_url`: URL for Grafana dashboard.
*   `minio_console_url`: URL for MinIO console (if enabled).

## License

MIT
