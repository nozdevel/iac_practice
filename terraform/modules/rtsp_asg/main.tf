resource "aws_instance" "rtsp" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[0] # サブネット1つを選択
  security_groups             = [var.security_group_id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  iam_instance_profile = var.instance_profile_name

  user_data = templatefile("${path.module}/user_data.sh.tpl", {})

  tags = {
    Name = "${var.name_prefix}-rtsp"
  }
}
