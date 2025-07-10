resource "aws_iam_role" "ssm_role" {
  name = "${var.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "bastion_ec2_policy" {
  name        = "${var.name_prefix}-bastion-ec2-policy"
  description = "Allow EC2 describe for bastion"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeSecurityGroups"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ec2" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.bastion_ec2_policy.arn
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
