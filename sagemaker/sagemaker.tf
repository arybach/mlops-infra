resource "aws_security_group" "sagemaker" {
  name        = "${local.resource_prefix}-sagemaker-security-group-${local.resource_suffix}"
  description = "Sagemaker notebook security group"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
  }
  
  # egress to anywhere within VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  }

  # egress to NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  }

  tags = local.standard_tags
}

# Create a SageMaker domain
resource "aws_sagemaker_domain" "this" {
  domain_name = var.domain
  auth_mode = "IAM"

  # Network isolation settings
  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
  
  # public subnets for easy access to Metaflow service
  subnet_ids = data.terraform_remote_state.infra.outputs.public_subnets
  

  default_user_settings {
    execution_role = data.terraform_remote_state.metaflow.outputs.metaflow_user_role_arn
    security_groups = [
      aws_security_group.sagemaker.id,
      data.terraform_remote_state.infra.outputs.nat_sg_id,
      data.terraform_remote_state.metaflow.outputs.metaflow_service_sg_id
    ]

    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path = "s3://${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}/sagemaker"
    }
  }

  tags = {
    Name = "${var.domain}-domain"
  }
}

# Create a SageMaker user profile
resource "aws_sagemaker_user_profile" "this" {
  domain_id = aws_sagemaker_domain.this.id
  user_profile_name = "sagemaker-user"

  # User settings
  user_settings {
    execution_role = data.terraform_remote_state.metaflow.outputs.metaflow_user_role_arn
    security_groups = [
      aws_security_group.sagemaker.id,
      data.terraform_remote_state.infra.outputs.nat_sg_id
    ]
    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path = "s3://${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}/sagemaker"
    }
  }

  tags = {
    Name = "sagemaker-user-profile"
  }
}

# Create a SageMaker shared space (app image config)
resource "aws_sagemaker_app_image_config" "this" {

  app_image_config_name = "sagemaker-workspace-config"
  
  # App image config settings
  kernel_gateway_image_config {
    kernel_spec {
      name = "python3"
      display_name = "Python 3"
    }
    # You can also specify the Docker image URI here
  }

  tags = {
    Name = "example-shared-space"
  }
}

# # test config to use when notebook is stuck in pending and times out
# resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "this" {
#   name = "${local.resource_prefix}-nb-instance-lc-conf-${local.resource_suffix}"
# }

# installing full package
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "this" {
  name = "${local.resource_prefix}-nb-instance-lc-conf-${local.resource_suffix}"

  # on_create = base64encode(file("${path.module}/on_create.sh"))
  # on_start  = base64encode(file("${path.module}/on_start.sh"))

  # short version if no need to install any packages or on timeout issues
  # make sure no special characters in any of the secrets - otherwise it will time out`
  on_start = base64encode(
<<EOF
#!/bin/bash
touch /etc/profile.d/jupyter-env.sh
echo 'export METAFLOW_DATASTORE_SYSROOT_S3=s3://${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}/metaflow/' >> /etc/profile.d/jupyter-env.sh
echo 'export METAFLOW_DATATOOLS_S3ROOT=s3://${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}/data/' >> /etc/profile.d/jupyter-env.sh
echo 'export METAFLOW_SERVICE_URL=${data.terraform_remote_state.metaflow.outputs.METAFLOW_SERVICE_INTERNAL_URL}' >> /etc/profile.d/jupyter-env.sh
echo 'export AWS_DEFAULT_REGION=${var.aws_region}' >> /etc/profile.d/jupyter-env.sh
echo 'export METAFLOW_DEFAULT_DATASTORE=s3' >> /etc/profile.d/jupyter-env.sh
echo 'export METAFLOW_DEFAULT_METADATA=service' >> /etc/profile.d/jupyter-env.sh
export PATH=/home/ec2-user/miniconda/bin:$PATH
export PATH=/home/ec2-user/anaconda3/bin:$PATH
echo "export AWS_ACCESS_KEY_ID=${local.secrets.AWS_ACCESS_KEY_ID}" >> /etc/profile.d/jupyter-env.sh
echo "export AWS_SECRET_ACCESS_KEY=${local.secrets.AWS_SECRET_ACCESS_KEY}" >> /etc/profile.d/jupyter-env.sh
echo "export AWS_REGION=${local.secrets.AWS_REGION}" >> /etc/profile.d/jupyter-env.sh
echo "export OPENAI_API_KEY=${local.secrets.OPENAI_API_KEY}" >> /etc/profile.d/jupyter-env.sh
echo "export S3_BUCKET_NAME=${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}" >> /etc/profile.d/jupyter-env.sh
echo "export METAFLOW_BATCH_CONTAINER_IMAGE=${data.terraform_remote_state.metaflow.outputs.metaflow_batch_container_image}" >> /etc/profile.d/jupyter-env.sh
echo "export METAFLOW_BATCH_JOB_QUEUE=${data.terraform_remote_state.metaflow.outputs.METAFLOW_BATCH_JOB_QUEUE}" >> /etc/profile.d/jupyter-env.sh
conda init bash
# Create a virtual environment with Python 3.9 and activate it
conda create -y -n sagemaker python=3.9 ipykernel
conda install -y -n sagemaker conda
conda activate sagemaker
pip install ipykernel
python -m ipykernel install --user --name sagemaker --display-name sagemaker_py_3.9
conda deactivate
sudo systemctl --no-block restart jupyter-server.service
EOF
)
}


resource "random_pet" "this" {
}

resource "aws_sagemaker_notebook_instance" "this" {
  # Random Pet name is added to make it easier to deploy changes to this instance without having name conflicts
  # names must be unique, so the "Random Pet" helps us here
  name = "${local.resource_prefix}-nb-inst-${random_pet.this.id}-${local.resource_suffix}"

  instance_type = var.ec2_instance_type
  volume_size   = var.volume_size
  
  role_arn     = aws_iam_role.sagemaker_execution_role.arn

  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.this.name

  # using public subnet 1 to connect to Metaflow service in the same subnet
  subnet_id       = data.terraform_remote_state.infra.outputs.subnet1_id

  security_groups = [
    aws_security_group.sagemaker.id,
    data.terraform_remote_state.infra.outputs.nat_sg_id,
    data.terraform_remote_state.metaflow.outputs.metaflow_service_sg_id
  ]

  # The standard tags to apply to every AWS resource.
  tags = local.standard_tags
}
