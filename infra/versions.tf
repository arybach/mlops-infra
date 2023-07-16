terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.38.0"
      #version = ">=4.31"
    }
  }
  required_version = ">= 0.13"
}
