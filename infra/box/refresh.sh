#!/bin/bash
set -euo pipefail
R=us-west-2
C=beginly-analytics
I=beginly-analytics-1
log() { echo "$(date -u +%FT%TZ) $*"; }

if aws rds describe-db-instances --region $R --db-instance-identifier $I >/dev/null 2>&1; then
  log "deleting instance $I"
  aws rds delete-db-instance --region $R --db-instance-identifier $I >/dev/null
  aws rds wait db-instance-deleted --region $R --db-instance-identifier $I
fi
if aws rds describe-db-clusters --region $R --db-cluster-identifier $C >/dev/null 2>&1; then
  log "deleting cluster $C"
  aws rds delete-db-cluster --region $R --db-cluster-identifier $C --skip-final-snapshot >/dev/null
  aws rds wait db-cluster-deleted --region $R --db-cluster-identifier $C
fi

log "cloning beginlyproduction-cluster"
aws rds restore-db-cluster-to-point-in-time --region $R --source-db-cluster-identifier beginlyproduction-cluster \
  --db-cluster-identifier $C --restore-type copy-on-write --use-latest-restorable-time \
  --db-subnet-group-name rds-ec2-db-subnet-group-2 --vpc-security-group-ids sg-00a2d740343c1413c \
  --serverless-v2-scaling-configuration MinCapacity=0,MaxCapacity=4 --tags Key=Purpose,Value=analytics >/dev/null
aws rds wait db-cluster-available --region $R --db-cluster-identifier $C

log "creating instance $I"
aws rds create-db-instance --region $R --db-cluster-identifier $C --db-instance-identifier $I \
  --db-instance-class db.serverless --engine aurora-postgresql --no-publicly-accessible \
  --tags Key=Purpose,Value=analytics >/dev/null
aws rds wait db-instance-available --region $R --db-instance-identifier $I

log "replacing master password"
MASTER=$(aws secretsmanager get-secret-value --region $R --secret-id beginly/analytics/master --query SecretString --output text)
aws rds modify-db-cluster --region $R --db-cluster-identifier $C --master-user-password "$MASTER" --apply-immediately >/dev/null
for _ in $(seq 60); do
  PENDING=$(aws rds describe-db-clusters --region $R --db-cluster-identifier $C --query 'DBClusters[0].PendingModifiedValues.MasterUserPassword' --output text)
  [ "$PENDING" = "None" ] && break
  sleep 10
done

log "scrubbing and granting reader"
for attempt in $(seq 10); do
  if /opt/metabase/bin/scrub-and-grant.sh; then
    log "refresh complete"
    exit 0
  fi
  log "scrub attempt $attempt failed, retrying"
  sleep 30
done
log "REFRESH FAILED: clone exists but has no reader login"
exit 1
