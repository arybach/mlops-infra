variable ec2_volume_size {
    type = number
    description = "EC2 root volume size (GB)"
    default = 50
}

variable ec2_volume_type {
    type = string
    description = "EC2 instance volume type for AMI"
    default = "gp2"
}

# t2.large = 2 vCPU + 8 GB RAM, t3.medium 4GB RAM
variable instance_type {
    type = string
    description = "EC2 instance type for AMI - vCPUs and RAM settings are overridable at launch by AWS Batch"
    default = "m5.xlarge"
    # default = "t3.xlarge"
}

# check AMI id of the standard Ubuntu 22.04 AMI if Ubuntu machine is needed
# aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" "Name=state,Values=available" --query "reverse(sort_by(Images, &CreationDate))[:1].ImageId" --output text
# ami-062550af7b9fa7d05
# Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type (Sagemaker is not on Linux 2023 yet - ami-03e312c9b09e29831)
# ami-0b3a4110c36b9a5f0
# using Linux 2023 here to build custom image for EMR ami-0126086c4e272d3c9

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  # default = "ami-062550af7b9fa7d05" # user would be ubuntu -> so update file location destinations
  default = "ami-0126086c4e272d3c9" # user is ec2-user
}

variable "key_name" {
  type = string
  description = "Name of the SSH key pair"
  default     = "evidently"
}

