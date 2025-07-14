# IaC Practice: Auto Scaling RTSP Server with Ansible & Lambda

## 注意: LambdaのENI削除について

AWS LambdaをVPC内で利用した場合、Lambda関数の削除後もENI（Elastic Network Interface）がしばらく残ることがあります。これはAWS側の仕様であり、TerraformではENI自体を直接削除・制御できません。
ENIはLambda関数の削除完了後、AWSが自動的に削除しますが、数分～十数分程度の遅延が発生する場合があります。ENIが残っている間は、関連するセキュリティグループ（SG）の削除もブロックされることがあります。
どうしてもENIが残り続ける場合は、AWSコンソールやCLIで手動削除してください（Description欄にLambda関数名が記載されていれば安全です）。
Terraform destroy時にSG削除が遅い場合は、ENIがSGを参照していることが主な原因です。Lambda→ENI→SGの削除順序はAWS側の自動制御となります。

## 概要

このリポジトリは、Terraform・Ansible・AWS Lambda・GitHub Actionsを用いて、  
Auto Scalingで起動したEC2にRTSPサーバ（MediaMTX）を自動構成するためのIaCサンプルです。

- TerraformでVPC, Bastion, NAT, RTSP EC2, IAM, NLB, LambdaなどAWSリソースを構築
- AnsibleでRTSP EC2にMediaMTX・ffmpeg・S3動画連携を自動設定
- LambdaでAuto Scaling EC2起動イベントを検知し、Bastion経由でAnsibleを再実行
- GitHub ActionsでCI/CD・構成管理

## 必要な実行環境

- Terraform
- Docker

## ディレクトリ構成

```
.
├── .github/workflows/upload_to_bastion.yml   # CI/CDワークフロー
├── ansible/                                 # Ansible Playbook・ロール・インベントリ
│   ├── playbook.yml
│   ├── run_with_reload_hosts.sh
│   ├── inventory/
│   │   └── hosts
│   ├── roles/
│   │   └── simple_rtsp/
│   │       ├── tasks/main.yml
│   │       └── templates/mediamtx.yml.j2
│   └── scripts/update_rtsp_inventory.py
├── config/                                  # 環境ごとの設定ファイル
│   ├── dev.yml
│   ├── prod.yml
│   └── sample.yml
├── lambda/lauch_ansible_trigger/            # Lambda用Pythonコード
│   └── lambda_function.py
├── terraform/                               # Terraform構成
│   ├── main.tf
│   ├── variables.tf
│   ├── versions.tf
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   ├── sample.tfvars_sample
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   ├── variables.tf
│   │   └── locals.tf
│   ├── prod/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   ├── modules/
│   │   ├── bastion_ansible/
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── user_data.sh.tpl
│   │   │   └── variables.tf
│   │   ├── github_oidc_role/
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── iam/
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── lambda_ec2_launch_ansible_trigger/
│   │   │   ├── Dockerfile
│   │   │   ├── lambda_build.sh
│   │   │   ├── lambda_layer.zip
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── variables.tf
│   │   │   └── build/
│   │   │       ├── lambda_function.py
│   │   │       ├── six.py
│   │   │       ├── ...（依存ライブラリ多数）
│   │   ├── nat/
│   │   ├── nlb/
│   │   ├── route/
│   │   ├── rtsp_asg/
│   │   ├── sg/
│   │   └── vpc/
└── README.md
```

## 初期セットアップ

1. **Lambda ZIPのビルド・依存パッケージの準備**

   ```sh
   cd terraform/modules/lambda_ec2_launch_ansible_trigger
   bash lambda_build.sh
   ```
   build/ ディレクトリに依存ライブラリとlambda_function.pyが展開されます
   lambda_layer.zipも自動生成されます

2. **Terraformでインフラ構築**

   ```sh
   cd terraform/dev
   terraform init
   terraform apply
   ```

3. **GitHub Actionsによる自動構成**

   `.github/workflows/upload_to_bastion.yml`を手動またはPushで実行

## 主な機能

- Bastion経由でAnsibleを実行し、RTSP EC2にMediaMTX・ffmpeg・S3動画連携を自動設定
- Auto Scalingで新規EC2が起動すると、LambdaがBastionにSSHしてAnsibleを再実行
- S3から動画ファイルをダウンロードし、ffmpegでRTSPストリームを常時配信
- Lambda用DockerfileでPython依存パッケージをレイヤー化し、軽量な実行環境を構築

## 注意事項

- AWS認証情報や秘密鍵は`.gitignore`で管理対象外です。漏洩に注意してください。
- S3バケット名や環境変数は`config/dev.yml`等で管理します。
- Lambda ZIPには`lambda_function.py`と依存ライブラリ（build/配下）が含まれている必要があります。
- DockerfileでENTRYPOINTを`/bin/bash`に変更しているため、Lambdaのカスタム実行やデバッグが容易です。


## 運用・トラブルシュートのポイント

- **TerraformのSecurity Group管理方針**
  - SG本体（aws_security_group）にはタグ・名前のみを定義し、すべての許可ルールはaws_security_group_ruleで分離管理しています。
  - これによりapplyごとにSGルールが変化する冪等性の問題を防止しています。
  - SG本体とSGルールの重複定義はエラーの原因となるため、必ず分離してください。

- **SGルールの履歴確認方法**
  - AWSコンソールのCloudTrailで「AuthorizeSecurityGroupIngress」「RevokeSecurityGroupIngress」イベントを検索することで、SGルールの追加・削除履歴を確認できます。
  - CLI例: `aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AuthorizeSecurityGroupIngress`

- **EC2のuser_dataでIMDSv2（インスタンスメタデータサービスv2）必須の場合、トークン取得によるインスタンスID取得が必要です。**
  - 例: `TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")`
        `INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)`

- **Auto Scaling Groupでuser_dataを更新した場合は、Launch Templateの新バージョンがASGに反映されているか確認し、既存インスタンスは入れ替えが必要です。**

- **LambdaトリガーはEC2のcloud-init（user_data）と起動時のsystemdで自作スクリプトから直接呼び出す方式です。EventBridgeは利用していません。**

- **IAMロールには`lambda:InvokeFunction`権限が必要です。**

- **Lambdaの実行結果は`/var/log/user-data.log`や`/tmp/lambda_output.json`で確認できます。**

- **AWSコンソールの反映遅延やキャッシュに注意し、apply後は数分待ってから確認してください。**

- **冪等性・トラブル時のチェックポイント**
  - SGルールがapplyごとに変化する場合は、SG本体とSGルールの重複定義がないか確認してください。
  - AWSコンソールやCLIで手動編集が入っていないか、CloudTrailで履歴を確認してください。
  - Terraform stateファイルの不整合が疑われる場合は`terraform refresh`で最新状態を取得してください。

## ライセンス

MIT License