#!/bin/bash
set -e

# 必要な環境変数をセット（必要に応じて編集）
export ENV=${ENV:-dev}
export AWS_REGION=${AWS_REGION:-ap-northeast-1}

# インベントリを最新化
python3 scripts/update_rtsp_inventory.py

# RTSP EC2のIPをknown_hostsに追加
rm -f ~/.ssh/known_hosts
for ip in $(awk '/^[0-9]+\./ {print $1}' inventory/hosts); do
  ssh-keyscan -H $ip >> ~/.ssh/known_hosts 2>/dev/null
done

# Playbookを実行
ansible-playbook -i inventory/hosts playbook.yml