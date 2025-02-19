variable "db_name" {
  description = "(Optional) Name of the connector DB"
  default     = "connectordb"
}

variable "db_username" {
  description = "(Optional) DB username"
  default     = "connector"
}

variable "db_password" {
  description = "(Optional) DB password"
  default     = "connectorpwd"
}