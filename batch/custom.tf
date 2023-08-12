# Build and push Docker image to ECR
resource "null_resource" "build_and_push_batch_image" {
  provisioner "local-exec" {
    command = "./batch_ecr.sh ${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name} ${data.terraform_remote_state.metaflow.outputs.metaflow_batch_container_image} ${local.secrets.AWS_ACCESS_KEY_ID} ${local.secrets.AWS_SECRET_ACCESS_KEY} ${local.secrets.AWS_REGION} ${local.secrets.OPENAI_API_KEY} ${local.secrets.HUGGING_FACE_TOKEN} ${local.secrets.USDA_API_KEY} ${local.secrets.ES_PASSWORD} ${local.secrets.ES_LOCAL_HOST} ${local.secrets.WANDB_API_KEY}"
  }
  depends_on = [data.terraform_remote_state.metaflow]
}

locals {
    ecr_docker_image    = file("batch_image_tag.txt")
    depends_on = [null_resource.build_and_push_batch_image ]
}

output "ecr_batch_image_link" {
  value = trim(local.ecr_docker_image, "\n")
}

# output "ebs_volume_id" {
#   value = aws_ebs_volume.ebs_batch.id
# }