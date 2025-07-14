
output "private_route_table_id" {
  value = aws_route_table.private.id # ← 'private_to_nat' → 'private'
}
