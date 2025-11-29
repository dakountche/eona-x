output "vault_url" {
  value = "http://vault:${local.vault_port}"
}

output "vault_token_secret_name" {
  value = kubernetes_secret.vault-secret.metadata.0.name
}