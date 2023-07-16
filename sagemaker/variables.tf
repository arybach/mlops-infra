variable "app" {
  default     = "sagemaker"
  description = "Name of the application"
}

variable "aws_region" {
  type        = string
  description = "AWS region we will deploy to."
}

variable "env" {
  type        = string
  default     = "mlops"
  description = "The environment for this stack to be created in. Used for the tfstate bucket and naming scope of resources."
}

variable "ec2_instance_type" {
  type        = string
  description = "Amazon EC2 instance type used to stand up SageMaker instance"
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "Amazon EC2 instance disk size for SageMaker instance"
  default = 30
}

variable "aws_ami_id" {
  description = "Amazon EC2 instance os image - default Ubuntu 22.04 amd64"
  default = "ami-082b1f4237bd816a1"
}

variable "iam_partition" {
  type        = string
  default     = "aws"
  description = "IAM Partition (Select aws-us-gov for AWS GovCloud, otherwise leave as is)"
}

variable "domain" {
  type        = string
  default     = "sagemaker"
  description = "Default Sagemaker domain name"
}

variable "add_bucket_arn" {
  type        = list(string)
  default     = ["arn:aws:s3:::usda.nutrients", "arn:aws:s3:::mlops-nutrients"]
  description = "Additional bucket ARNs to allow access to"
}