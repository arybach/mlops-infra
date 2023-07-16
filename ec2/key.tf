resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_name       # Create key to AWS!!
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  depends_on  = [tls_private_key.pk]

  filename = "${aws_key_pair.kp.key_name}.pem"
  content = tls_private_key.pk.private_key_pem

  provisioner "local-exec" {
    command = "sleep 10 && chmod 400 ${aws_key_pair.kp.key_name}.pem"
  }
}

output "key_name" {
  value = local_file.ssh_key.filename
}
