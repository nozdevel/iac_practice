variable "lambda_sg_id" {
  description = "Lambda Security Group ID for Bastion ingress rule"
  type        = string
  default     = ""
}
variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "nlb_cidr_block" {
  type = string
}

variable "bastion_src_ip" {
  type = string
}