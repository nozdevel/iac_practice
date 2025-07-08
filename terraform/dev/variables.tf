variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 key pair"
  type        = string
}

variable "own_ip" {
  type = string
}