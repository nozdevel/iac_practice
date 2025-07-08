#!/bin/bash

# ログファイル
exec > /var/log/user-data.log 2>&1

echo "[INFO] Start user-data"

# パッケージインストール
dnf update -y || true
dnf install -y iptables-services amazon-ssm-agent || true

# IP転送有効化
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/custom-ip-forwarding.conf
sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf

PRIMARY_IF=$(ip route | awk '/^default/ { print $5 }')

/sbin/iptables -t nat -A POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE
/sbin/iptables -A FORWARD -i "$PRIMARY_IF" -j ACCEPT
/sbin/iptables -A FORWARD -o "$PRIMARY_IF" -j ACCEPT
service iptables save || echo "[WARN] iptables save failed"

systemctl enable iptables
systemctl restart iptables || echo "[WARN] iptables failed"

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

echo "[INFO] user-data finished"
