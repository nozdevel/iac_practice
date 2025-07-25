variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID to launch Bastion host in"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for Bastion host"
  type        = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "sg_id" {
  type = string
}

variable "key_name" {
  description = "Key pair name for SSH"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for bastion"
  type        = string
}

variable "s3_bucket" {
  description = "S3バケット名（dev.ymlから取得）"
  type        = string
}
