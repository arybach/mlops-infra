resource "aws_security_group" "nat_sg" {
  name_prefix = "nat_sg"
  description = "Security group for NAT Gateway"
  vpc_id      = aws_vpc.this.id

  # Ingress rules for inbound traffic to the NAT Gateway (if needed)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rules for outbound traffic from the NAT Gateway to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

# To fine tune the security group, you can add more ingress/egress rules
  # ingress {
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = ["${aws_vpc.this.cidr_block}"]
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks  = ["0.0.0.0/0"] # otherwise emr in the private subnet can not download packages
  # }

  # ingress {
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "udp"
  #   cidr_blocks = ["${aws_vpc.this.cidr_block}"]
  # }

  # Allow inbound traffic from my ip for debugging
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["192.168.18.29/32"] # my ip
  # }

  # # Allow inbound traffic from my ip for debugging
  # ingress {
  #   from_port   = 7077
  #   to_port     = 7077
  #   protocol    = "tcp"
  #   cidr_blocks = ["192.168.18.29/32"] # my ip
  # }

  tags = {
    Name = "nat_sg"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ingress,
      egress,
      vpc_id,
      tags,
    ]
  }
}

