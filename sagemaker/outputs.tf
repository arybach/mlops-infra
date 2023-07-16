output "sagemaker_sg_id" {
  value = aws_security_group.sagemaker.id
}

output "sagemaker_role_arn" {
  value = aws_iam_role.sagemaker_execution_role.arn
}

output "SAGEMAKER_NOTEBOOK_URL" {
  value       = "https://${aws_sagemaker_notebook_instance.this.name}.notebook.${var.aws_region}.sagemaker.aws/tree"
  description = "URL used to access the SageMaker notebook instance"
}
