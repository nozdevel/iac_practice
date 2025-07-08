variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for the internal NLB"
}

variable "vpc_id" {
  type = string
}

variable "asg_name" {
  type = string
}
