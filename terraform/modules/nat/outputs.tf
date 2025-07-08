output "nat_instance_id" {
  value = aws_instance.this.id
}

output "nat_eni_id" {
  value = aws_instance.this.primary_network_interface_id
}

output "eip" {
  value = aws_eip.this.public_ip
}
