variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 key pair"
  type        = string
}

variable "bastion_src_ip" {
  description = "The source access cidr of bastion"
  type        = string
}

variable "github_repo" {
  type = string
}