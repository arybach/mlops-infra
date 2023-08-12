resource "aws_security_group" "evidently_sg" {
  name_prefix = "evidently-sg-ssh"

  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id

  # needed for debugging - should be turned off in production
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this is needed to connect to streamlit UI
  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this is needed to connect to fastapi externally
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow TCP ingress from localhost to port 5432
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  }
  
  # # intra-vpc tcp traffic
  # ingress {
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  # }

  # intra-vpc udp traffic
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
  
  # egress to anywhere 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # # egress to NAT Gateway
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  # }

  tags = {
    Name = "evidently-security-group"
  }
}



resource "aws_network_interface" "evidently_network_interface" {
  subnet_id       = data.terraform_remote_state.infra.outputs.subnet1_id

  security_groups = [
      aws_security_group.evidently_sg.id,
      data.terraform_remote_state.infra.outputs.nat_sg_id,
      data.terraform_remote_state.metaflow.outputs.metaflow_service_sg_id,
    ]

  tags = {
    Name = "evidently-network-interface"
  }
}

resource "aws_eip" "evidently_eip" {
  
  domain = "vpc"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "evidently-eip"
  }
}

# Associate EIP with network interface
resource "aws_eip_association" "evidently_eip_association" {
  network_interface_id = aws_network_interface.evidently_network_interface.id
  allocation_id        = aws_eip.evidently_eip.id
}

resource "aws_iam_role" "evidently_iam_role" {
  name = "EvidentlyUserRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "EC2AccessPolicy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:*",
            "s3:*",
            "ecr:*",
            "emr:*",
            "cloudwatch:*",
            "kms:*",
            "logs:*",
            "ebs:*",
            "efs:*"
          ],
          "Resource": "*"
        }
      ]
    })
  }

  # Check if the role already exists
  lifecycle {
    ignore_changes = [name]
    # Only create the role if it doesn't exist
    create_before_destroy = true
  }
}

data "aws_iam_role" "existing_role" {
  name = aws_iam_role.evidently_iam_role.name
}

resource "aws_instance" "evidently_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  # public key on AWS 
  key_name      = aws_key_pair.kp.key_name 
  
  timeouts {
    create = "10m"
    delete = "3m"
  }
  
  root_block_device {
    volume_type           = var.ec2_volume_type
    volume_size           = var.ec2_volume_size
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.evidently_network_interface.id
    device_index         = 0
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.evidently_eip.public_ip
    }
    source      = "./provision.sh"
    destination = "/home/ec2-user/provision.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.evidently_eip.public_ip
    }

    inline = [
      "mkdir -m 777 -p /home/ec2-user/mlops-evidently",
      "chmod +x /home/ec2-user/provision.sh",
      "sudo /home/ec2-user/provision.sh",
      "sudo reboot",
    ]
  }


  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.evidently_eip.public_ip
    }

    # copies over all env vars, starts up docker-compose and runs test scripts - reports should be available via ec2_ip:5000/docs#/ or streamlit ec2_ip:8501
    inline = [
      "cd /home/ec2-user/",
      "git clone --branch main https://github.com/arybach/mlops-evidently.git",
      "echo \"export AWS_ACCESS_KEY_ID=${local.secrets.AWS_ACCESS_KEY_ID}\" >> ~/.bashrc",
      "echo \"export AWS_SECRET_ACCESS_KEY=${local.secrets.AWS_SECRET_ACCESS_KEY}\" >> ~/.bashrc",
      "echo \"export AWS_REGION=${local.secrets.AWS_REGION}\" >> ~/.bashrc",
      "echo \"export S3_BUCKET_NAME=${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}\" >> ~/.bashrc",
      "echo \"export ES_LOCAL_HOST=${data.terraform_remote_state.ec2.outputs.eip_public_ip}\" >> ~/.bashrc",
      "echo \"export ES_PASSWORD=${local.secrets.ES_PASSWORD}\" >> ~/.bashrc",
      "echo \"export ES_LOCAL_HOST=${local.secrets.ES_LOCAL_HOST}\" >> ~/.bashrc",
      "echo \"export POSTGRES_USER=${local.secrets.POSTGRES_USER}\" >> ~/.bashrc",
      "echo \"export POSTGRES_PASSWORD=${local.secrets.POSTGRES_PASSWORD}\" >> ~/.bashrc",
      "source ~/.bashrc",
      "cd /home/ec2-user/mlops-evidently",
      "docker-compose up -d"
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.evidently_eip.public_ip
    }

    # copies over all env vars, starts up docker-compose and runs test scripts - reports should be available via ec2_ip:5000/docs#/ or streamlit ec2_ip:8501
    inline = [
      "cd /home/ec2-user/mlops-evidently",
      "pip install -r requirements.txt",
      "pip install wheel",
      "python3 setup.py bdist_wheel",
      "python3 src/scripts/create_db.py",
      # this is for debugging (make sure ES_LOCAL_HOST and ES_PASSWORD env vars are properly set in the vault and on the machine before running)
      "python3 src/pipelines/load_data.py", 
      "python3 src/pipelines/process_data.py",
      "python3 src/pipelines/prepare_reference_data.py",
      "python3 src/scripts/simulate.py xgboost_model",
      "python3 src/scripts/simulate.py linear_regression_model"
    ]
    # to check ssh into an ec2 instance, run the scripts above and then python3 query.py to check data in db
  }

  tags = {
    Name = "evidently-ec2"
  }
}

output "eip_public_ip" {
  value = aws_eip.evidently_eip.public_ip
}

output "evidently_sg_id" {
  value = aws_security_group.evidently_sg.id
}

output "evidently_iam_role_name" {
  value = aws_iam_role.evidently_iam_role.name
}

output "private_ip_address" {
  value = aws_instance.evidently_instance.private_ip
}

output "internal_dns_hostname" {
  value = aws_instance.evidently_instance.private_dns
}