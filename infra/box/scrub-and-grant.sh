#!/bin/bash
set -euo pipefail
H=beginly-analytics.cluster-cxam43dpp1ju.us-west-2.rds.amazonaws.com
MASTER=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id beginly/analytics/master --query SecretString --output text)
READER=$(aws secretsmanager get-secret-value --region us-west-2 --secret-id beginly/analytics/reader --query SecretString --output text)
docker exec -i -e PGPASSWORD="$MASTER" metabase-db psql -h "$H" -U postgres -d beginlydemo -v ON_ERROR_STOP=1 -v pw="$READER" -q <<'SQL'
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['sessions','personal_access_tokens','password_reset_tokens','jobs','job_batches','failed_jobs','cache','cache_locks','telescope_monitoring','telescope_entries_bak'] LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN EXECUTE format('TRUNCATE %I', t); END IF;
  END LOOP;
  IF to_regclass('public.telescope_entries') IS NOT NULL THEN TRUNCATE telescope_entries_tags, telescope_entries; END IF;
END $$;
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('users','password','NULL'), ('users','remember_token','NULL'),
    ('users','two_factor_secret','NULL'), ('users','two_factor_recovery_codes','NULL'),
    ('incomplete_registrations','password','NULL'), ('incomplete_registrations','verification_token','NULL'),
    ('connected_accounts','token','md5(token)'), ('connected_accounts','secret','NULL'), ('connected_accounts','refresh_token','NULL'),
    ('notification_tokens','token','md5(token)'),
    ('push_subscriptions','auth_token','NULL'),
    ('feed_subscriptions','credentials','NULL'),
    ('ingestion_feeds','credentials','NULL'),
    ('analytics_all_candidates','password','NULL'), ('analytics_all_candidates','remember_token','NULL'),
    ('analytics_all_candidates','two_factor_secret','NULL'), ('analytics_all_candidates','two_factor_recovery_codes','NULL')
  ) v(tbl, col, expr) LOOP
    IF EXISTS (SELECT 1 FROM information_schema.columns ic JOIN pg_class c ON c.relname = ic.table_name JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
               WHERE ic.table_schema = 'public' AND ic.table_name = r.tbl AND ic.column_name = r.col AND c.relkind IN ('r','p')) THEN
      EXECUTE format('UPDATE %I SET %I = %s', r.tbl, r.col, r.expr);
    END IF;
  END LOOP;
END $$;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = 'analytics_all_candidates' AND c.relkind = 'm') THEN
    REFRESH MATERIALIZED VIEW analytics_all_candidates;
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'metabase_reader') THEN CREATE ROLE metabase_reader LOGIN; END IF;
END $$;
ALTER ROLE metabase_reader WITH LOGIN PASSWORD :'pw';
ALTER ROLE metabase_reader SET default_transaction_read_only = on;
ALTER ROLE metabase_reader SET statement_timeout = '5min';
GRANT CONNECT ON DATABASE beginlydemo TO metabase_reader;
GRANT pg_read_all_data TO metabase_reader;
SQL
echo "scrub + grant done"
docker exec -e PGPASSWORD="$READER" metabase-db psql -h "$H" -U metabase_reader -d beginlydemo -Atc "select 'kind of analytics_all_candidates', relkind::text from pg_class where relname = 'analytics_all_candidates' union all select 'users passwords left', count(*)::text from users where password is not null union all select 'analytics_all_candidates passwords left', count(*)::text from analytics_all_candidates where password is not null union all select 'ingestion_feeds credentials left', count(*)::text from ingestion_feeds where credentials is not null union all select 'telescope_entries_bak rows', count(*)::text from telescope_entries_bak"
