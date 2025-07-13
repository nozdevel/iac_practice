resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# Public Route Table (→ IGW)
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# Private Route Table (→ NAT Instance)
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = var.nat_eni_id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}

# Private用ネットワークACL
resource "aws_network_acl" "private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-private-nacl"
  }
}

# Inbound: VPC内からのSSH (TCP/22) を許可
resource "aws_network_acl_rule" "private_in_allow_ssh" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
  from_port      = 22
  to_port        = 22
}

# Inbound: VPC内からの通信を許可（全プロトコル）
resource "aws_network_acl_rule" "private_in_allow_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# Inboundルール: Ephemeralポート (TCP 1024-65535) を許可
resource "aws_network_acl_rule" "private_in_allow_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound: 全トラフィック許可
resource "aws_network_acl_rule" "private_out_allow_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# NACLとPrivate Subnetの紐付け
resource "aws_network_acl_association" "private_nacl_assoc" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  network_acl_id = aws_network_acl.private.id
}
