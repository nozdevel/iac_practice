variable "env" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

locals {
  config_file = "${path.module}/../../config/${var.env}.yml"
  vars        = yamldecode(file(local.config_file))

  region        = local.vars.region
  environment   = local.vars.environment
  project_name  = local.vars.project_name
  instance_type = local.vars.instance_type
}
