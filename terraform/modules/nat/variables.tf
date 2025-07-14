variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_subnet_id" {
  type = string
}


variable "instance_profile_name" {
  type = string
}

variable "sg_id" {
  type = string
}

variable "key_name" {
  description = "Key pair name for SSH"
  type        = string
}