resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile = var.iam_instance_profile

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    s3_bucket = var.s3_bucket
  })

  tags = {
    Name = "${var.name_prefix}-bastion-ansible"
  }
}