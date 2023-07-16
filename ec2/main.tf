provider "aws" {
  #region = var.aws_region
  region = data.terraform_remote_state.infra.outputs.aws_region
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = "environment"
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../infra/terraform.tfstate"
  }
}

data "terraform_remote_state" "metaflow" {
  backend = "local"

  config = {
    path = "../metaflow/terraform.tfstate"
  }
}

# if needed to work with sagemaker
# data "terraform_remote_state" "sagemaker" {
#   backend = "local"

#   config = {
#     path = "../sagemaker/terraform.tfstate"
#   }
# }

