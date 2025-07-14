variable "lambda_function_name" {
  type        = string
  description = "Lambda関数名"
  default     = "trigger_ansible_on_ec2_launch"
}

variable "environment" {
  description = "Lambda ENV value"
  type        = string
}

variable "bastion_ssh_key_secret_name" {
  description = "Secrets Manager key name"
  type        = string
}

variable "bastion_ssh_user" {
  description = "Bastion SSH user"
  type        = string
}

variable "ansible_command" {
  type        = string
  description = "bastionで実行するansibleコマンド"
  default     = "cd ~/ansible && ansible-playbook -i inventory playbook.yml"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambdaランタイム"
  default     = "python3.9"
}

variable "lambda_handler" {
  type        = string
  description = "Lambdaハンドラ"
  default     = "lambda_function.lambda_handler"
}

variable "lambda_zip_path" {
  type        = string
  description = "Lambda ZIPファイルのパス"
}

variable "s3_bucket" {
  description = "S3バケット名（dev.ymlから取得）"
  type        = string
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda function"
  type        = list(string)
}

variable "lambda_security_group_ids" {
  description = "List of security group IDs for Lambda function"
  type        = list(string)
}
