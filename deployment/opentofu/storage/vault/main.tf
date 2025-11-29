locals {
  vault_token = "root"
  vault_port  = 8200
  vault_image = "hashicorp/vault:1.17.2"
}

resource "kubernetes_stateful_set" "vault" {
  metadata {
    name = "vault"
    labels = {
      app = "vault"
    }
  }

  spec {
    service_name = "vault"
    replicas     = 1

    selector {
      match_labels = {
        app = "vault"
      }
    }

    template {
      metadata {
        labels = {
          app = "vault"
        }
      }

      spec {
        container {
          name  = "vault"
          image = local.vault_image

          args = ["server", "-dev"] # Vault in dev mode

          port {
            container_port = 8200
            name           = "http"
          }

          env {
            name  = "VAULT_DEV_ROOT_TOKEN_ID"
            value = local.vault_token
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vault" {
  metadata {
    name = "vault"
    labels = {
      app = "vault"
    }
  }

  spec {
    selector = {
      app = "vault"
    }

    port {
      port        = 8200
      target_port = 8200
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "vault-ingress" {
  metadata {
    name = "vault-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/vault(/|$)(.*)"
          backend {
            service {
              name = kubernetes_service.vault.metadata.0.name
              port {
                number = local.vault_port
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_secret" "vault-secret" {
  metadata {
    name = "vault"
  }

  data = {
    rootToken = local.vault_token
  }
}