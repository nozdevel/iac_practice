# IaC Practice: Auto Scaling RTSP Server with Ansible & Lambda

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
│   ├── inventory/hosts
│   ├── roles/simple_rtsp/
│   └── scripts/update_rtsp_inventory.py
├── config/                                  # 環境ごとの設定ファイル
│   ├── dev.yml
│   └── prod.yml
├── lambda/lauch_ansible_trigger/            # Lambda用Pythonコード
│   ├── lambda_function.py
│   └── requirements.txt
├── terraform/                               # Terraform構成
│   ├── main.tf
│   ├── variables.tf
│   ├── versions.tf
│   ├── dev/
│   ├── modules/
│   └── prod/
└── README.md
```

## 初期セットアップ

1. **Terraformでインフラ構築**

   ```sh
   cd terraform/dev
   terraform init
   terraform apply
   ```

2. **Lambda ZIPのビルド**

   ```sh
   cd terraform/modules/lambda_ec2_launch_ansible_trigger
   bash lambda_build.sh
   ```

3. **GitHub Actionsによる自動構成**

   `.github/workflows/upload_to_bastion.yml`を手動またはPushで実行

## 主な機能

- Bastion経由でAnsibleを実行し、RTSP EC2にMediaMTX・ffmpeg・S3動画連携を自動設定
- Auto Scalingで新規EC2が起動すると、LambdaがBastionにSSHしてAnsibleを再実行
- S3から動画ファイルをダウンロードし、ffmpegでRTSPストリームを常時配信

## 注意事項

- AWS認証情報や秘密鍵は`.gitignore`で管理対象外です。漏洩に注意してください。
- S3バケット名や環境変数は`config/dev.yml`等で管理します。
- Lambda ZIPには`lambda_function.py`と依存ライブラリが含まれている必要があります。

## 運用・トラブルシュートのポイント

- EC2のuser_dataでIMDSv2（インスタンスメタデータサービスv2）必須の場合、トークン取得によるインスタンスID取得が必要です。
  - 例: `TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")`
        `INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)`
- Auto Scaling Groupでuser_dataを更新した場合は、Launch Templateの新バージョンがASGに反映されているか確認し、既存インスタンスは入れ替えが必要です。
- LambdaトリガーはEC2のcloud-init（user_data）から直接呼び出す方式です。EventBridgeは利用していません。
- IAMロールには`lambda:InvokeFunction`権限が必要です。
- Lambdaの実行結果は`/var/log/user-data.log`や`/tmp/lambda_output.json`で確認できます。
- AWSコンソールの反映遅延やキャッシュに注意し、apply後は数分待ってから確認してください。

## ライセンス

MIT License