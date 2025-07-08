#!/bin/bash

set -euxo pipefail
#exec > /var/log/user-data.log 2>&1

# NATゲートウェイ（10.0.1.1 など）への通信ができるようになるまで待つ
#while ! curl -s --max-time 2 http://amazon.com > /dev/null; do
#  echo "Waiting for NAT to become available..."
#  sleep 5
#done

dnf update -y
dnf install -y docker
systemctl enable --now docker
systemctl start docker
# Docker起動後、AnsibleでRTSP server導入予定

# SSM Agentの明示的起動
dnf install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent
systemctl restart amazon-ssm-agent