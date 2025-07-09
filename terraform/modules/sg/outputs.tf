output "rtsp_ec2_sg_id" {
  value = aws_security_group.rtsp_sg.id
}

output "nat_sg_id" {
  value = aws_security_group.nat_sg.id
}

output "bastion_sg_id" {
  description = "Security Group ID of the Bastion host"
  value       = aws_security_group.bastion_sg.id
}