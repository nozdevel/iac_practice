output "rtsp_profile_name" {
  value = aws_iam_instance_profile.rtsp_ec2_profile.name
}

output "rtsp_role_arn" {
  value = aws_iam_role.rtsp_ec2_role.arn
}

output "bastion_instance_profile_name" {
  value = aws_iam_instance_profile.bastion_instance_profile.name
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion_ansible_role.arn
}

output "nat_instance_profile_name" {
  value = aws_iam_instance_profile.nat_instance_profile.name
}

output "nat_role_arn" {
  value = aws_iam_role.nat_instance_role.arn
}
