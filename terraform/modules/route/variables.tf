variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "nat_eni_id" {
  type = string
}

variable "vpc_cidr_block" {
  description = "VPCのCIDRブロック（例: 10.0.0.0/16）"
  type        = string
}
