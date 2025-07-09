#!/bin/bash

# ログファイル
exec > /var/log/user-data.log 2>&1

echo "[INFO] Start user-data"

# パッケージインストール
dnf update -y || true
dnf install -y ansible amazon-ssm-agent || true

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

echo "[INFO] user-data finished"
