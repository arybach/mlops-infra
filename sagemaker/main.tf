provider "aws" {
  #region = var.aws_region
  region = data.terraform_remote_state.infra.outputs.aws_region

}

module "common_vars" {
  source = "../modules/common"

  app = var.app
  env = var.env
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

data "terraform_remote_state" "ec2" {
  backend = "local"

  config = {
    path = "../ec2/terraform.tfstate"
  }
}

