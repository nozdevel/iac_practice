#!/bin/bash

# ログファイル
exec > /var/log/user-data.log 2>&1

echo "[INFO] Start user-data"

# パッケージインストール
dnf update -y || true
dnf install -y amazon-ssm-agent || true

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

dnf install -y python3-pip git

# Ansible インストール
pip3 install --upgrade pip
pip3 install ansible

# 実行環境をインストール
pip3 install boto3 awscli

# Ansible の動作確認ログ出力（オプション）
ansible --version > /var/log/ansible_version.log

# ec2-user を対象に Ansible の作業ディレクトリ作成
mkdir -p /home/ec2-user/ansible
chown ec2-user:ec2-user /home/ec2-user/ansible

echo "[INFO] user-data finished"
