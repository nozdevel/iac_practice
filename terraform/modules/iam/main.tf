##############################
# RTSP EC2 用 IAMリソース
##############################

resource "aws_iam_role" "rtsp_ec2_role" {
  name = "${var.name_prefix}-rtsp-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.rtsp_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.rtsp_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "${var.name_prefix}-lambda-invoke-policy"
  description = "Allow EC2 to invoke specific Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction"
        ],
        Resource = "arn:aws:lambda:ap-northeast-1:942035140949:function:trigger_ansible_on_ec2_launch"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_invoke" {
  role       = aws_iam_role.rtsp_ec2_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

resource "aws_iam_instance_profile" "rtsp_ec2_profile" {
  name = "${var.name_prefix}-rtsp-ec2-profile"
  role = aws_iam_role.rtsp_ec2_role.name
}

##############################
# Bastion 用 IAMリソース
##############################

resource "aws_iam_role" "bastion_ansible_role" {
  name = "${var.name_prefix}-bastion-ansible-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "bastion_ansible_inline_policy" {
  name = "${var.name_prefix}-bastion-ansible-inline-policy"
  role = aws_iam_role.bastion_ansible_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "ec2:DescribeSecurityGroups"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "${var.name_prefix}-bastion-ansible-profile"
  role = aws_iam_role.bastion_ansible_role.name
}

##############################
# NAT 用 IAMリソース
##############################

resource "aws_iam_role" "nat_instance_role" {
  name = "${var.name_prefix}-nat-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "${var.name_prefix}-nat-profile"
  role = aws_iam_role.nat_instance_role.name
}
