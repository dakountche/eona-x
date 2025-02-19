###################
## POSTGRESQL DB ##
###################

module "postgres" {
  source = "./postgres"
}

#####################
## HASHICORP VAULT ##
#####################
module "vault" {
  source = "./vault"
}