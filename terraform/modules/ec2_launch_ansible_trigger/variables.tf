variable "lambda_function_name" {
  type        = string
  description = "Lambda関数名"
  default     = "trigger_ansible_on_ec2_launch"
}

variable "bastion_host_param_name" {
  type        = string
  description = "SSM Parameter Storeのパラメータ名（bastionホスト/IP）"
}

variable "bastion_ssh_key_secret_name" {
  type        = string
  description = "Secrets Managerのシークレット名（bastion SSH秘密鍵）"
}

variable "bastion_ssh_user" {
  type        = string
  description = "bastion接続用ユーザー名"
  default     = "ec2-user"
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
