# BASTION用セキュリティグループ
resource "aws_security_group" "bastion_sg" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
  }
}

resource "aws_security_group_rule" "bastion_ssh_from_cidr" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.bastion_src_ip]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

# BastionからRTSP EC2へのSSH許可ルール
resource "aws_security_group_rule" "rtsp_ec2_allow_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rtsp_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow SSH from Bastion to RTSP EC2"
}

# 循環参照回避、apply前に値が確定しない、Terraformの制約上、ここでresourceを定義
resource "aws_security_group_rule" "bastion_allow_lambda" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
  description              = "Allow SSH from Lambda to Bastion"
}

# NAT用セキュリティグループ
resource "aws_security_group" "nat_sg" {
  name        = "${var.name_prefix}-nat-sg"
  description = "Allow internal access and outbound internet for NAT"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-nat-sg"
  }
}

resource "aws_security_group_rule" "nat_inbound" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.nat_sg.id
}

resource "aws_security_group_rule" "nat_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat_sg.id
}


# lambda用セキュリティグループ
resource "aws_security_group" "lambda_sg" {
  name        = "${var.name_prefix}-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-lambda-sg"
  }
}

resource "aws_security_group_rule" "lambda_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_sg.id
}

# RTSP EC2用セキュリティグループ
resource "aws_security_group" "rtsp_sg" {
  name        = "${var.name_prefix}-rtsp-sg"
  description = "Security group for RTSP EC2 instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-rtsp-sg"
  }
}

resource "aws_security_group_rule" "rtsp_allow_rtsp" {
  type              = "ingress"
  from_port         = 554
  to_port           = 554
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rtsp_sg.id
}

resource "aws_security_group_rule" "rtsp_allow_ssh_tunnel_rtsp" {
  type              = "ingress"
  from_port         = 8554
  to_port           = 8554
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rtsp_sg.id
}

resource "aws_security_group_rule" "rtsp_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rtsp_sg.id
}
