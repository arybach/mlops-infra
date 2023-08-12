variable "AWS_ACCESS_KEY_ID" { default = null }
variable "AWS_SECRET_ACCESS_KEY" { default = null }
variable "AWS_REGION" { default = null }
variable "ES_PASSWORD" { default = null }
variable "ES_LOCAL_HOST" { default = null }
variable "POSTGRES_USER" { default = null }
variable "POSTGRES_PASSWORD" { default = null }

data "vault_generic_secret" "aws_creds" {
    path = "secret/aws"
}

locals {
  secrets = {
    AWS_ACCESS_KEY_ID      = coalesce(data.vault_generic_secret.aws_creds.data.AWS_ACCESS_KEY_ID, var.AWS_ACCESS_KEY_ID)
    AWS_SECRET_ACCESS_KEY  = coalesce(data.vault_generic_secret.aws_creds.data.AWS_SECRET_ACCESS_KEY, var.AWS_SECRET_ACCESS_KEY)
    AWS_REGION             = coalesce(data.vault_generic_secret.aws_creds.data.AWS_REGION, var.AWS_REGION)
    ES_PASSWORD            = coalesce(data.vault_generic_secret.aws_creds.data.ES_PASSWORD, var.ES_PASSWORD)
    ES_LOCAL_HOST          = coalesce(data.vault_generic_secret.aws_creds.data.ES_LOCAL_HOST, var.ES_LOCAL_HOST)
    POSTGRES_USER          = coalesce(data.vault_generic_secret.aws_creds.data.POSTGRES_USER, var.POSTGRES_USER)
    POSTGRES_PASSWORD      = coalesce(data.vault_generic_secret.aws_creds.data.POSTGRES_PASSWORD, var.POSTGRES_PASSWORD)
  }
}

