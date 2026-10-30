#!/bin/bash
set -euo pipefail
H=beginly-analytics.cluster-cxam43dpp1ju.us-west-2.rds.amazonaws.com
READER=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id beginly/analytics/reader --query SecretString --output text)
docker exec -i -e PGPASSWORD="$READER" metabase-db psql -h "$H" -U metabase_reader -d beginlydemo -At <<'SQL'
SELECT table_name || '.' || column_name || ' (' || data_type || ')'
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name ~* '(passw|token|secret|credential|api_?key|private|auth|otp|recovery|salt|hash|signature|cookie|session|bearer)'
ORDER BY table_name, column_name;
SQL
