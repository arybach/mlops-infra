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

## THIS CODE DEPLOYS VAULT SERVER in public subnet of the project's vpc - no need for now

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "3.58.0"
#     }
#   }
# }

# data "vault_generic_secret" "aws_creds" {
#     path = "secret/aws"
# }

# provider "aws" {
#   AWS_ACCESS_KEY_ID     = data.vault_generic_secret.aws_creds.data["AWS_ACCESS_KEY_ID"]
#   AWS_SECRET_ACCESS_KEY = data.vault_generic_secret.aws_creds.data["AWS_SECRET_ACCESS_KEY"]
#   AWS_REGION            = data.vault_generic_secret.aws_creds.data["AWS_REGION"]
#   OPENAI_API_KEY        = data.vault_generic_secret.aws_creds.data["OPENAI_API_KEY"]
#   HUGGING_FACE_TOKEN    = data.vault_generic_secret.aws_creds.data["HUGGING_FACE_TOKEN"]
#   USDA_API_KEY          = data.vault_generic_secret.aws_creds.data["USDA_API_KEY"]
#   ES_PASSWORD           = data.vault_generic_secret.aws_creds.data["ES_PASSWORD"]

# }

# to fetch ami
# $ aws ec2 describe-images --filters "Name=name,Values=amzn2-ami-hvm-2.0.????????.?-x86_64-gp2" "Name=architecture,Values=x86_64" "Name=block-device-mapping.volume-type,Values=gp2" "Name=root-device-type,Values=ebs" "Name=virtualization-type,Values=hvm" --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' --region ap-southeast-1 --output text
# ami-0b3585f7e59098316

# resource "aws_instance" "my_server" {
#   ami           = "ami-0b3585f7e59098316"
#   instance_type = "t2.nano"
#   vpc_id        = data.terraform_remote_state.infra.outputs.vpc_id
#   subnet_id     = data.terraform_remote_state.infra.outputs.subnet1_id

#     tags = {
#         Name = "Vault-Server"
#     }
# }