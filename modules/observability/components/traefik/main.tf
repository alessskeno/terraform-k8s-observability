resource "kubernetes_namespace" "traefik" {
  count = var.traefik_enabled ? 1 : 0
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  count      = var.traefik_enabled ? 1 : 0
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = kubernetes_namespace.traefik[0].metadata[0].name
  version    = var.traefik_version
  atomic     = false
  timeout    = 300

  values = [
    yamlencode({
      tolerations = [
        {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        },
      ]
      ingressClass = {
        enabled        = true
        isDefaultClass = true
      }
      service = {
        type = "ClusterIP"
      }
      ports = {
        web = {
          port     = 8000
          hostPort = 80
        }
        websecure = {
          port     = 8443
          hostPort = 443
        }
      }
      providers = {
        kubernetesCRD = {
          allowCrossNamespace = true
        }
      }
    })
  ]
}
