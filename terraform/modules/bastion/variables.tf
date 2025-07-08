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

variable "key_name" {
  description = "Key pair name for SSH"
  type        = string
}

variable "own_ip" {
  type = string
}
