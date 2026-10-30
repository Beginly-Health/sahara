#!/bin/bash
set -euo pipefail
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
KEY=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id beginly/analytics/tailscale-authkey --query SecretString --output text)
tailscale up --auth-key="$KEY" --hostname=beginly-metabase --advertise-tags=tag:metabase
tailscale serve --bg 3000
tailscale serve status
