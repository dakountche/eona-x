#####################
## CREATE DB, USER ##
#####################

resource "kubernetes_config_map" "db-init-script" {

  metadata {
    name = "${var.db_user}-db-init"
  }

  data = {
    "init.sh" = file("${path.module}/db_init.sh")
  }
}


resource "kubernetes_job_v1" "db-init" {
  metadata {
    name = "${var.db_user}-db-init"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name  = "postgres"
          image = "postgres:15.3-alpine3.18"
          command = [
            "sh",
            "/db/scripts/init.sh"
          ]

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name     = var.postgres_admin_credentials_secret_name
                key      = "POSTGRES_USER"
                optional = false
              }
            }
          }

          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name     = var.postgres_admin_credentials_secret_name
                key      = "POSTGRES_PASSWORD"
                optional = false
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name     = var.postgres_admin_credentials_secret_name
                key      = "POSTGRES_DB"
                optional = false
              }
            }
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name  = "DB_NAME"
            value = var.db_name
          }

          env {
            name  = "DB_FQDN"
            value = var.db_server_fqdn
          }

          env {
            name  = "DB_PASSWORD"
            value = var.db_user_password
          }

          volume_mount {
            mount_path = "/db/scripts"
            name       = "db-init-script"
          }
        }

        volume {
          name = "db-init-script"
          config_map {
            name = kubernetes_config_map.db-init-script.metadata.0.name
          }
        }

        restart_policy = "OnFailure"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
}

resource "kubernetes_secret" "db-user-credentials" {

  metadata {
    name = var.db_name
  }

  data = {
    "username" = var.db_user
    "password" = var.db_user_password
  }
}