#!/bin/bash
# EC2 user data for the Metabase server. This is the corrected version of what launched
# i-0a431e12387d827cd: the original used `tr </dev/urandom | head`, which fails under
# pipefail, and `set -x`, which printed the password into the cloud-init log.
set -euo pipefail
dnf -y update
dnf -y install docker dnf-automatic
sed -i 's/^upgrade_type.*/upgrade_type = security/; s/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
systemctl enable --now docker dnf-automatic.timer
install -d -m 700 /opt/metabase /opt/metabase/pgdata
PW=$(openssl rand -hex 24)
printf 'POSTGRES_USER=metabase\nPOSTGRES_PASSWORD=%s\nPOSTGRES_DB=metabase\n' "$PW" > /opt/metabase/postgres.env
printf 'MB_DB_TYPE=postgres\nMB_DB_HOST=metabase-db\nMB_DB_PORT=5432\nMB_DB_DBNAME=metabase\nMB_DB_USER=metabase\nMB_DB_PASS=%s\nJAVA_OPTS=-Xmx2g\n' "$PW" > /opt/metabase/metabase.env
chmod 600 /opt/metabase/*.env
docker network create metabase
docker run -d --name metabase-db --restart unless-stopped --network metabase --env-file /opt/metabase/postgres.env -v /opt/metabase/pgdata:/var/lib/postgresql/data postgres:16-alpine
docker run -d --name metabase --restart unless-stopped --network metabase --env-file /opt/metabase/metabase.env -p 127.0.0.1:3000:3000 metabase/metabase:latest
