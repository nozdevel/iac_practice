output "lambda_function_arn" {
  description = "Lambda関数のARN"
  value       = aws_lambda_function.lambda_ec2_launch_ansible_trigger.arn
}

output "lambda_execution_role_arn" {
  description = "Lambda実行ロールのARN"
  value       = aws_iam_role.lambda_exec_role.arn
}
