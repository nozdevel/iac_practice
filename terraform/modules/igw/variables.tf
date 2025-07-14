variable "vpc_id" {
  description = "VPC ID to attach IGW"
  type        = string
}

variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
  default     = ""
}
