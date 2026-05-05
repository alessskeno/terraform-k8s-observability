terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.cert_manager_enabled ? 1 : 0
  metadata {
    name = "cert-manager"
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

resource "helm_release" "cert_manager" {
  count      = var.cert_manager_enabled ? 1 : 0
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager[0].metadata[0].name
  version    = var.cert_manager_version
  atomic     = true

  values = [
    yamlencode({
      installCRDs = true
    })
  ]
}

# Self-Signed Issuer (Default)
resource "kubectl_manifest" "selfsigned_issuer" {
  count = var.cert_manager_enabled ? 1 : 0

  server_side_apply = true
  wait              = true
  force_new         = true
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "selfsigned-issuer"
      namespace = helm_release.cert_manager[0].namespace
    }
    spec = {
      selfSigned = {}
    }
  })
}

resource "kubectl_manifest" "cluster_root_ca" {
  count = var.cert_manager_enabled ? 1 : 0

  server_side_apply = true
  wait              = true
  force_new         = true
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "cluster-root-ca"
      namespace = helm_release.cert_manager[0].namespace
    }
    spec = {
      isCA       = true
      commonName = "cluster-root-ca"
      secretName = "cluster-root-ca"
      privateKey = {
        algorithm = "RSA"
        size      = 2048
      }
      issuerRef = {
        name = kubectl_manifest.selfsigned_issuer[0].name
        kind = "Issuer"
      }
    }
  })
}

resource "kubectl_manifest" "cluster_ca_issuer" {
  count = var.cert_manager_enabled ? 1 : 0

  server_side_apply = true
  wait              = true
  force_new         = true
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cluster-ca-issuer"
    }
    spec = {
      ca = {
        secretName = yamldecode(kubectl_manifest.cluster_root_ca[0].yaml_body).spec.secretName
      }
    }
  })
}
