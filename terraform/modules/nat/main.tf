resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  source_dest_check           = false
  disable_api_termination     = false
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = var.instance_profile_name
  key_name                    = var.key_name


  #user_data = templatefile("${path.module}/user_data.sh.tpl", {
  #  eip_public_ip = aws_eip.this.public_ip
  #})
  user_data = templatefile("${path.module}/user_data.sh.tpl", {})

  tags = {
    Name = "${var.name_prefix}-nat"
  }
}

resource "aws_eip" "this" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}
