locals {
  resource_prefix = var.app
  resource_suffix = "${var.env}${module.common_vars.workspace_suffix}"

  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
  standard_tags  = module.common_vars.tags

  # Name of Sagemaker IAM role
  sagemaker_execution_role_name = "${local.resource_prefix}-sm-execution-role-${local.resource_suffix}-${var.aws_region}"
}

variable "AWS_ACCESS_KEY_ID" { default = null }
variable "AWS_SECRET_ACCESS_KEY" { default = null }
variable "AWS_REGION" { default = null }
variable "OPENAI_API_KEY" { default = null }

data "vault_generic_secret" "aws_creds" {
    path = "secret/aws"
}

locals {
  secrets = {
    AWS_ACCESS_KEY_ID      = coalesce(data.vault_generic_secret.aws_creds.data.AWS_ACCESS_KEY_ID, var.AWS_ACCESS_KEY_ID)
    AWS_SECRET_ACCESS_KEY  = coalesce(data.vault_generic_secret.aws_creds.data.AWS_SECRET_ACCESS_KEY, var.AWS_SECRET_ACCESS_KEY)
    AWS_REGION             = coalesce(data.vault_generic_secret.aws_creds.data.AWS_REGION, var.AWS_REGION)
    OPENAI_API_KEY         = coalesce(data.vault_generic_secret.aws_creds.data.OPENAI_API_KEY, var.OPENAI_API_KEY)
  }
}
