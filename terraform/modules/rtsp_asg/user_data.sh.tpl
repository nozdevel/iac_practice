#!/bin/bash

# ログファイル

exec > /var/log/user-data.log 2>&1

echo "[INFO] Start user-data"

# Terraformからregionを埋め込む
export REGION="${region}"
echo "[INFO] REGION set to $REGION"

dnf update -y
dnf install -y docker
systemctl enable --now docker
systemctl start docker
# Docker起動後、AnsibleでRTSP server導入予定

# SSM Agentの明示的起動
dnf install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent
systemctl restart amazon-ssm-agent

dnf install -y jq
# IMDSv2対応でインスタンスID取得
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id | tr -cd '[:alnum:]-')
echo "[INFO] INSTANCE_ID: $INSTANCE_ID"
echo "[INFO] REGION: $REGION"

if [ -n "$INSTANCE_ID" ]; then
  PAYLOAD=$(printf '{"instance_id":"%s"}' "$INSTANCE_ID")
  echo "[INFO] lambda invoke payload: $PAYLOAD"
  echo "$PAYLOAD" > /tmp/lambda_payload.json
  cat -v /tmp/lambda_payload.json

  aws lambda invoke \
    --function-name trigger_ansible_on_ec2_launch \
    --payload fileb:///tmp/lambda_payload.json \
    /tmp/lambda_output.json \
    --region $REGION
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    echo "[ERROR] lambda invoke failed with status $STATUS"
    [ -f /tmp/lambda_output.json ] && cat /tmp/lambda_output.json
  else
    echo "[INFO] lambda invoke completed"
    cat /tmp/lambda_output.json
  fi
else
  echo "[ERROR] instance-id取得失敗"
fi


cat <<'EOF' > /usr/local/bin/rtsp_ansible_trigger.sh
${RTSP_TRIGGER_SH}
EOF
chmod +x /usr/local/bin/rtsp_ansible_trigger.sh

# REGION変数を環境変数として設定するため、変数展開ありのcatで出力
cat <<EOF > /etc/systemd/system/rtsp_ansible_trigger.service
[Unit]
Description=Invoke Lambda to trigger Ansible on RTSP EC2 boot/restart
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=REGION=$REGION
ExecStart=/usr/local/bin/rtsp_ansible_trigger.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now rtsp_ansible_trigger.service

echo "[INFO] user-data finished"