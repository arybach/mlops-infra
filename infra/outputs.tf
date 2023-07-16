output "subnet1_id" {
  value       = aws_subnet.subnet1.id
  description = "Public subnet 1 used for availability zone redundancy"
}

output "subnet2_id" {
  value       = aws_subnet.subnet2.id
  description = "Public subnet 2 used for availability zone redundancy"
}

output "subnet3_id" {
  value       = aws_subnet.subnet3.id
  description = "Private subnet 3 used for EMR serverless"
}

output "vpc_cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "The CIDR block we've designated for this VPC"
}

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The id of the single VPC we stood up for all Metaflow resources to exist in."
}

output "public_subnets" {
  value = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

output "private_subnets" {
   value = [aws_subnet.subnet3.id]
}

output "nat_sg_id" {
  value = aws_security_group.nat_sg.id
}

output "cidr_block1" {
  value = aws_subnet.subnet1.cidr_block
}

output "cidr_block2" {
  value = aws_subnet.subnet2.cidr_block
}

output "cidr_block3" {
  value = aws_subnet.subnet3.cidr_block
}

output "nat_gateway_ip" {
  value = aws_eip.nat_eip.public_ip
}

output "aws_region" {
  value = var.aws_region
}

output "private_route_table_id" {
  value = aws_route_table.private_route_table.id
}