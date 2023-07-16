variable "access_list_cidr_blocks" {
  type        = list(string)
  description = "List of CIDRs we want to grant access to our Metaflow Metadata Service. Usually this is your VPN's CIDR blocks."
  default   = []
  # default     = ["192.168.18.29/32"] # my ip
}

variable "api_basic_auth" {
  type        = bool
  default     = false
  description = "Enable basic auth for API Gateway? (requires key export)"
}

variable "with_public_ip" {
  type        = bool
  default     = true
  description = "Enable public access for API Gateway?"
}

variable "app" {
  default     = "metaflow"
  description = "Name of the application"
}

variable "aws_region" {
  type        = string
  description = "AWS region we will deploy to."
}

variable "batch_type" {
  type        = string
  description = "AWS Batch Compute Type ('ec2', 'fargate')"
  default     = "ec2"
}

variable "compute_environment_desired_vcpus" {
  type        = number
  description = "Desired Starting VCPUs for Batch Compute Environment [0-16] for EC2 Batch Compute Environment (ignored for Fargate)"
  default     = 2
}

variable "compute_environment_instance_types" {
  type        = list(string)
  description = "The instance types for the compute environment"
  default     = ["c4.large", "c4.xlarge", "c4.2xlarge"]
  #default     = ["c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge"]
}

variable "compute_environment_max_vcpus" {
  type        = number
  description = "Maximum VCPUs for Batch Compute Environment [16-96]"
  default     = 16
}

variable "compute_environment_min_vcpus" {
  type        = number
  description = "Minimum VCPUs for Batch Compute Environment [0-16] for EC2 Batch Compute Environment (ignored for Fargate)"
  default     = 0
}

variable "cpu_max_compute_vcpus" {
  type        = number
  description = "Minimum gpus"
}

variable "cpu_min_compute_vcpus" {
  type        = number
  description = "Minimum gpus"
}

variable "cpu_desired_compute_vcpus" {
  type        = number
  description = "Desired gpus"
}

variable "large_cpu_max_compute_vcpus" {
  type        = number
  description = "Minimum gpus"
}

variable "large_cpu_min_compute_vcpus" {
  type        = number
  description = "Minimum gpus"
}

variable "large_cpu_desired_compute_vcpus" {
  type        = number
  description = "Desired gpus"
}


variable "gpu_min_compute_vcpus" {
  type        = number
  description = "Minimum gpus"
}

variable "gpu_max_compute_vcpus" {
  type        = number
  description = "Minimum gpus"
}

variable "gpu_desired_compute_vcpus" {
  type        = number
  description = "Desired gpus"
}

variable "custom_role" {
  type        = bool
  default     = true
  description = "Enable custom role with restricted permissions?"
}

variable "enable_custom_batch_container_registry" {
  type        = bool
  default     = true
  description = "Provisions infrastructure for custom ECR container registry if enabled"
}

variable "enable_step_functions" {
  type        = bool
  default     = true
  description = "Provisions infrastructure for step functions if enabled"
}

variable "env" {
  type        = string
  default     = "mlops"
  description = "The environment for this stack to be created in. Used for the tfstate bucket and naming scope of resources."
}

variable "iam_partition" {
  type        = string
  default     = "aws"
  description = "IAM Partition (Select aws-us-gov for AWS GovCloud, otherwise leave as is)"
}

variable "add_bucket_arn" {
  type        = list(string)
  default     = ["arn:aws:s3:::usda.nutrients", "arn:aws:s3:::mlops-nutrients"]
  description = "Additional bucket ARNs to allow access to"
}