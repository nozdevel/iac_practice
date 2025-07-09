variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (e.g. 'my-org/my-repo')"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM Role to create"
  type        = string
  default     = "github-actions-role"
}

variable "assume_branch" {
  description = "GitHub branch allowed to assume the role (ref format without 'refs/heads/')"
  type        = string
  default     = "main"
}

variable "policy_statements" {
  description = "List of IAM policy statements (JSON objects) to attach to the role"
  type        = list(any)
  default = [
    {
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = ["*"]
    }
  ]
}
