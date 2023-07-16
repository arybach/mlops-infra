resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2-sg-ssh"

  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this is needed for @batch flows to connect to elastic search
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this is needed to connect to kibana GUI
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this is needed to connect to logstash
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# this is needed to connect to logstash
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# this is needed to connect to logstash
  ingress {
    from_port   = 12201
    to_port     = 12201
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  
  # egress to anywhere 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # egress to NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr_block]
  }

  tags = {
    Name = "ec2-security-group"
  }
}



resource "aws_network_interface" "ec2_network_interface" {
  subnet_id       = data.terraform_remote_state.infra.outputs.subnet1_id

  security_groups = [
      aws_security_group.ec2_sg.id,
      data.terraform_remote_state.infra.outputs.nat_sg_id,
      data.terraform_remote_state.metaflow.outputs.metaflow_service_sg_id,
    ]

  tags = {
    Name = "ec2-network-interface"
  }
}

resource "aws_eip" "ec2_eip" {
  
  domain = "vpc"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ec2-eip"
  }
}

# Associate EIP with network interface
resource "aws_eip_association" "ec2_eip_association" {
  network_interface_id = aws_network_interface.ec2_network_interface.id
  allocation_id        = aws_eip.ec2_eip.id
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "EC2UserRole"

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
  name = aws_iam_role.ec2_iam_role.name
}

# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "EC2InstanceProfile"
#   role = data.aws_iam_role.existing_role.id
# }

resource "aws_instance" "ec2_instance" {
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
    network_interface_id = aws_network_interface.ec2_network_interface.id
    device_index         = 0
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.ec2_eip.public_ip
    }
    source      = "./provision.sh"
    destination = "/home/ec2-user/provision.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.ec2_eip.public_ip
    }

    inline = [
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
      host        = aws_eip.ec2_eip.public_ip
    }

    inline = [
      "mkdir -p /home/ec2-user/.metaflowconfig",
      "mkdir -p /home/ec2-user/elk_tls",
      "cd /home/ec2-user/",
      "git clone --branch tls https://github.com/deviantony/docker-elk.git",
      "cd docker-elk",
      "docker-compose up tls",
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.ec2_eip.public_ip
    }
    source      = "~/.metaflowconfig/config.json"
    destination = "/home/ec2-user/.metaflowconfig/config.json"
  }

  # specify your passwords in .env file before creating the resource
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.ec2_eip.public_ip
    }
    source      = "./.env"
    destination = "/home/ec2-user/elk_tls/.env"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.ec2_eip.public_ip
    }

    // Execute the provision.sh script on the remote machine
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID=${local.secrets.AWS_ACCESS_KEY_ID}\" >> ~/.bashrc",
      "echo \"export AWS_SECRET_ACCESS_KEY=${local.secrets.AWS_SECRET_ACCESS_KEY}\" >> ~/.bashrc",
      "echo \"export AWS_REGION=${local.secrets.AWS_REGION}\" >> ~/.bashrc",
      "echo \"export OPENAI_API_KEY=${local.secrets.OPENAI_API_KEY}\" >> ~/.bashrc",
      "echo \"export HUGGING_FACE_TOKEN=${local.secrets.HUGGING_FACE_TOKEN}\" >> ~/.bashrc",
      "echo \"export USDA_API_KEY=${local.secrets.USDA_API_KEY}\" >> ~/.bashrc",
      "echo \"export S3_BUCKET_NAME=${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}\" >> ~/.bashrc",
      "echo \"export BATCH_CONTAINER_NAME=${data.terraform_remote_state.metaflow.outputs.metaflow_batch_container_image}\" >> ~/.bashrc",
      "source ~/.bashrc",
      "cp /home/ec2-user/elk_tls/* /home/ec2-user/docker-elk/",
      "cd /home/ec2-user/docker-elk",
      "docker-compose up setup",
    ]
  }

  # if any changes are needed to the docker-compose pass your own version before docker-compose up
  # provisioner "file" {
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = tls_private_key.pk.private_key_pem
  #     host        = aws_eip.ec2_eip.public_ip
  #   }
  #   source      = "./docker-compose.yml"
  #   destination = "/home/ec2-user/elk_tls/docker-compose.yml"
  # }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.pk.private_key_pem
      host        = aws_eip.ec2_eip.public_ip
    }

    // Execute the provision.sh script on the remote machine
    inline = [
      "cp /home/ec2-user/elk_tls/* /home/ec2-user/docker-elk/",
      "cd /home/ec2-user/docker-elk/",
      "nohup docker-compose up > /dev/null 2>&1 &",
    ]
  }

  tags = {
    Name = "elastic-ec2"
  }
}

output "eip_public_ip" {
  value = aws_eip.ec2_eip.public_ip
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}

output "ec2_iam_role_name" {
  value = aws_iam_role.ec2_iam_role.name
}

    # inline = [
    #   // Additional step 1: Create directories
    #   "mkdir -p /home/ec2-user/.metaflowconfig",
    #   "mkdir -p /home/ec2-user/elk_tls",
      
    #   // Additional step 2: Copy files to the remote machine
    #   "scp ~/.metaflowconfig/config.json ec2-user@${aws_eip.ec2_eip.public_ip}:/home/ec2-user/.metaflowconfig/config.json",
    #   "scp .env ec2-user@${aws_eip.ec2_eip.public_ip}:/home/ec2-user/elk_tls/.env",
    #   "scp docker-compose.yml ec2-user@${aws_eip.ec2_eip.public_ip}:/home/ec2-user/elk_tls/docker-compose.yml",
    #   "scp install.sh ec2-user@${aws_eip.ec2_eip.public_ip}:/home/ec2-user/install.sh",
    #   "sudo chmod +x /home/ec2-user/install.sh && cd /home/ec2-user/ && bash install.sh",

    #   // Additional step 3: Export environment variables
    #   "echo \"export AWS_ACCESS_KEY_ID=${local.secrets.AWS_ACCESS_KEY_ID}\" >> ~/.bashrc",
    #   "echo \"export AWS_SECRET_ACCESS_KEY=${local.secrets.AWS_SECRET_ACCESS_KEY}\" >> ~/.bashrc",
    #   "echo \"export AWS_REGION=${local.secrets.AWS_REGION}\" >> ~/.bashrc",
    #   "echo \"export OPENAI_API_KEY=${local.secrets.OPENAI_API_KEY}\" >> ~/.bashrc",
    #   "echo \"export HUGGING_FACE_TOKEN=${local.secrets.HUGGING_FACE_TOKEN}\" >> ~/.bashrc",
    #   "echo \"export USDA_API_KEY=${local.secrets.USDA_API_KEY}\" >> ~/.bashrc",
    #   "echo \"export S3_BUCKET_NAME=${data.terraform_remote_state.metaflow.outputs.metaflow_s3_bucket_name}\" >> ~/.bashrc",
    #   "echo \"export BATCH_CONTAINER_NAME=${data.terraform_remote_state.metaflow.outputs.metaflow_batch_container_image}\" >> ~/.bashrc",
    #   "source ~/.bashrc",

    #   // Additional step 3: Run commands on the remote machine
    #   "cd /home/ec2-user/ && git clone https://github.com/swimlane/elk-tls-docker.git",
    #   "cp /home/ec2-user/elk_tls/* /home/ec2-user/elk-tls-docker/ && cd /home/ec2-user/elk-tls-docker/ && docker-compose up setup", 
    # ]
