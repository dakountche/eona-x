locals {
  pg_image    = "postgres:15.3-alpine3.18"
  pg_username = "postgres"
  pg_password = "postgres"
  pg_port     = 5432
}


###############
## DB CONFIG ##
###############

resource "kubernetes_secret" "db-admin-credentials" {
  metadata {
    name = "postgresql"
  }

  data = {
    POSTGRES_USER     = local.pg_username
    POSTGRES_PASSWORD = local.pg_password
    POSTGRES_DB       = "postgres"
  }
}

resource "kubernetes_config_map" "db-config" {
  metadata {
    name = "postgresql"
  }

  data = {
    "postgresql.conf" = file("${path.module}/config/postgresql.conf")
  }
}

########
## DB ##
########

resource "kubernetes_stateful_set" "db" {

  metadata {
    name = "postgresql"
  }

  spec {
    service_name = "postgres"
    replicas     = "1"

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        termination_grace_period_seconds = 30

        container {
          name  = "postgres"
          image = local.pg_image
          args  = ["-c", "config_file=/config/postgresql.conf"]

          port {
            container_port = local.pg_port
            name           = "database"
          }

          env {
            name  = "PGDATA"
            value = "/data/pgdata"
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name     = kubernetes_secret.db-admin-credentials.metadata.0.name
                key      = "POSTGRES_USER"
                optional = false
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name     = kubernetes_secret.db-admin-credentials.metadata.0.name
                key      = "POSTGRES_PASSWORD"
                optional = false
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name     = kubernetes_secret.db-admin-credentials.metadata.0.name
                key      = "POSTGRES_DB"
                optional = false
              }
            }
          }

          volume_mount {
            mount_path = "/config"
            name       = "config"
            read_only  = false
          }

          #          volume_mount {
          #            mount_path = "/data"
          #            name       = "data"
          #            read_only  = false
          #          }
        }

        volume {
          name = "config"
          config_map {
            name         = kubernetes_config_map.db-config.metadata.0.name
            default_mode = "0755"
          }
        }

      }
    }
  }
}

resource "kubernetes_service" "db-service" {
  metadata {
    name = "postgres"
    labels = {
      app = "postgres"
    }
  }

  spec {
    selector = {
      app = kubernetes_stateful_set.db.spec.0.template.0.metadata[0].labels.app
    }

    port {
      name        = "postgres"
      port        = local.pg_port
      target_port = local.pg_port
    }
  }
}

module "db" {
  source = "./db-bootstrap"

  db_name                                = var.db_name
  db_server_fqdn                         = kubernetes_service.db-service.metadata[0].name
  db_user                                = var.db_username
  db_user_password                       = var.db_password
  postgres_admin_credentials_secret_name = kubernetes_secret.db-admin-credentials.metadata.0.name
}
