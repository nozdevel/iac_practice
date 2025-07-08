#!/bin/bash

dnf update -y
dnf install -y docker
systemctl enable --now docker
systemctl start docker
# Docker起動後、AnsibleでRTSP server導入予定

# SSM Agentの明示的起動
dnf install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent
systemctl restart amazon-ssm-agent