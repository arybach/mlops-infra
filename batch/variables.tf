# variable ebs_volume_size {
#     type = number
#     description = "EBS volume to be shared by containers in the AWS Batch (GB)"
#     default = 200
# }

variable cluster_name {
    type = string
    description = "ECR cluster name"
    default = "mlops"
}

variable "mlops_bucket_name" {
    default = "mlops-nutrients"
}

# check AMI id of the standard Ubuntu 22.04 AMI
# aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" "Name=state,Values=available" --query "reverse(sort_by(Images, &CreationDate))[:1].ImageId" --output text
# ami-062550af7b9fa7d05

# variable "ami_id" {
#   description = "The ID of the AMI to use for the EC2 instance"
#   default = "ami-062550af7b9fa7d05"
# }

