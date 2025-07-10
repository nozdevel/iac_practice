#!/bin/bash
set -e

# 必要な環境変数をセット（必要に応じて編集）
export ENV=${ENV:-dev}
export AWS_REGION=${AWS_REGION:-ap-northeast-1}

# インベントリを最新化
python3 scripts/update_rtsp_inventory.py

# Playbookを実行
ansible-playbook -i