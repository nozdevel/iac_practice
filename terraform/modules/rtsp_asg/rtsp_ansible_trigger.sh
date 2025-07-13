#!/bin/bash
# RTSP EC2起動時・再起動時にLambdaをInvokeするサンプル
# IMDSv2対応でインスタンスID取得
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id | tr -cd '[:alnum:]-')
echo "[INFO] INSTANCE_ID: $INSTANCE_ID"
echo "[INFO] REGION: ${REGION}"

if [ -n "$INSTANCE_ID" ]; then
  PAYLOAD=$(printf '{"instance_id":"%s"}' "$INSTANCE_ID")
  echo "[INFO] lambda invoke payload: $PAYLOAD"
  echo "$PAYLOAD" > /tmp/lambda_payload.json
  cat -v /tmp/lambda_payload.json

  aws lambda invoke \
    --function-name trigger_ansible_on_ec2_launch \
    --payload fileb:///tmp/lambda_payload.json \
    /tmp/lambda_output.json \
    --region ${REGION}
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