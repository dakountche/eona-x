variable "db_name" {
  description = "(Required) Name of the DB to be created"
}

variable "db_user" {
  description = "(Required) Owner of the DB to be created"
}

variable "db_user_password" {
  description = "(Required) Password of the DB owner"
}

variable "db_server_fqdn" {
  description = "(Required) FQDN of the PostgreSQL server"
}

variable "postgres_admin_credentials_secret_name" {
  description = "(Required) Secret containing the DB Admin credentials"
}