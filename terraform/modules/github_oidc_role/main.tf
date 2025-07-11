# 名前がややこしいが、GitHubのOIDCプロバイダと、Relying Partyの連携させるためのリソース
resource "aws_iam_openid_connect_provider" "github" {
  # 連携先クライアントのURL
  url = "https://token.actions.githubusercontent.com"

  # Relying Partyのドメイン
  # 通常は sts.amazonaws.com (自前の認証先を用意している場合などに変わる)
  client_id_list = ["sts.amazonaws.com"]

  # クライアントのドメインが正しいことを証明するためのフィンガープリント
  # プロバイダがクライアントに接続した時に証明書のフィンガープリントが、こちらと一致するかチェックするのに使用
  thumbprint_list = data.tls_certificate.github_actions.certificates[*].sha1_fingerprint
}

data "http" "github_actions_openid_configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# フィンガープリントを動的に取得することでフィンガープリントが変わった時にも対応可能
data "tls_certificate" "github_actions" {
  url = jsondecode(data.http.github_actions_openid_configuration.response_body).jwks_uri
}

resource "aws_iam_role" "github_actions_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "custom_policy" {
  name        = "${var.role_name}-policy"
  description = "Policy attached to ${var.role_name} for GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.policy_statements,
      [
        {
          Effect = "Allow"
          Action = [
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "secretsmanager:CreateSecret",
            "secretsmanager:UpdateSecret",
            "secretsmanager:DeleteSecret",
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue"
          ]
          Resource = "*"
        }
      ]
    )
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.custom_policy.arn
}
