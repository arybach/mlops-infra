variable "AWS_ACCESS_KEY_ID" { default = null }
variable "AWS_SECRET_ACCESS_KEY" { default = null }
variable "AWS_REGION" { default = null }
variable "OPENAI_API_KEY" { default = null }
variable "HUGGING_FACE_TOKEN" { default = null }
variable "USDA_API_KEY" { default = null }
variable "ES_PASSWORD" { default = null }
variable "ES_LOCAL_HOST" { default = null }
variable "WANDB_API_KEY" { default = null }

data "vault_generic_secret" "aws_creds" {
    path = "secret/aws"
}

locals {
  secrets = {
    AWS_ACCESS_KEY_ID      = coalesce(data.vault_generic_secret.aws_creds.data.AWS_ACCESS_KEY_ID, var.AWS_ACCESS_KEY_ID)
    AWS_SECRET_ACCESS_KEY  = coalesce(data.vault_generic_secret.aws_creds.data.AWS_SECRET_ACCESS_KEY, var.AWS_SECRET_ACCESS_KEY)
    AWS_REGION             = coalesce(data.vault_generic_secret.aws_creds.data.AWS_REGION, var.AWS_REGION)
    OPENAI_API_KEY         = coalesce(data.vault_generic_secret.aws_creds.data.OPENAI_API_KEY, var.OPENAI_API_KEY)
    HUGGING_FACE_TOKEN     = coalesce(data.vault_generic_secret.aws_creds.data.HUGGING_FACE_TOKEN, var.HUGGING_FACE_TOKEN)
    USDA_API_KEY           = coalesce(data.vault_generic_secret.aws_creds.data.USDA_API_KEY, var.USDA_API_KEY)
    ES_PASSWORD            = coalesce(data.vault_generic_secret.aws_creds.data.ES_PASSWORD, var.ES_PASSWORD)
    ES_LOCAL_HOST          = coalesce(data.vault_generic_secret.aws_creds.data.ES_LOCAL_HOST, var.ES_LOCAL_HOST)
    WANDB_API_KEY          = coalesce(data.vault_generic_secret.aws_creds.data.WANDB_API_KEY, var.WANDB_API_KEY)
  }
}

