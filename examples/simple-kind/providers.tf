terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

provider "helm" {
  burst_limit = 900
  kubernetes = {
    host = var.kubernetes_cluster

    client_certificate     = base64decode(var.kubernetes_cluster_cert)
    client_key             = base64decode(var.kubernetes_cluster_key)
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca)
  }
}

provider "kubectl" {
  host = var.kubernetes_cluster

  client_certificate     = base64decode(var.kubernetes_cluster_cert)
  client_key             = base64decode(var.kubernetes_cluster_key)
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca)
  load_config_file       = false
}

provider "kubernetes" {
  host = var.kubernetes_cluster

  client_certificate     = base64decode(var.kubernetes_cluster_cert)
  client_key             = base64decode(var.kubernetes_cluster_key)
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca)
}
