output "instance_profile_name" {
  description = "IAM instance profile name for EC2 (bastion/ssm)"
  value       = aws_iam_instance_profile.ssm_profile.name
}

output "ssm_role_arn" {
  description = "ARN of the SSM role"
  value       = aws_iam_role.ssm_role.arn
}
