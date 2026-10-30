#!/bin/bash
set -euo pipefail
LOG=$(journalctl -u beginly-analytics-refresh.service --no-pager -n 25 -o cat)
aws sns publish --region us-west-2 --topic-arn arn:aws:sns:us-west-2:764882989014:beginly-cost-alerts \
  --subject "Beginly analytics refresh FAILED" \
  --message "The nightly refresh of the beginly-analytics copy failed on beginly-metabase (i-0a431e12387d827cd). Metabase may show yesterday's data or no data until it is rerun. Runbook: https://claude.ai/artifact/MUZoqwd6teMWiFmGGEAooS

Last log lines:
$LOG" >/dev/null
