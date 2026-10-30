# Sahara: Beginly Analytics

Home of Beginly's internal reporting: a self-hosted Metabase over a nightly, scrubbed copy of the
death-valley production database. This repo holds the infrastructure scripts and the SQL the team's
dashboards are built from. It is not an application; nothing here deploys automatically.

- ClickUp: Data Warehouse `86ajzu37e`
- Team guide + admin runbook: https://claude.ai/artifact/MUZoqwd6teMWiFmGGEAooS (keep it current when the setup changes)
- Metabase: https://beginly-metabase.tailbbd43a.ts.net (Beginly Tailscale network only)

## Rules

- **Security first.** Metabase has no inbound ports; access is Tailscale only. Don't propose public exposure.
- **Claude never connects to the data.** Claude reads code and schemas and writes SQL; people run it in Metabase.
  Metabase's AI features stay off. Both are gated on a privacy review that hasn't happened.
- **The scrub must keep up with the schema.** A new column that holds a password, token, secret or credential
  must be added to `infra/box/scrub-and-grant.sh`. `infra/box/audit-columns.sh` lists suspicious column names in the clone.
- **The scripts here are the source of truth** for what runs on the server. After changing one, push it to the box
  (see "Changing the server").
- Bryan runs AWS commands himself in CloudShell: hand over one copy-pasteable command at a time and wait for its output.

## Where the queries come from

The point of this repo is to centralize reporting SQL that is scattered across the codebases, including the
widgets, stats and reports each app already shows, rebuilt as Metabase questions and dashboards. All three repos
are readable from here (`.claude/settings.json` adds them as working directories). Sources to mine:

- `../death-valley/docs/sql/analytics-queries.md`: the existing catalog of analytics queries
- `../death-valley`: the candidate platform (production database `beginlydemo`; the demo-sounding name is expected)
- `../carcross`: the Employer app. It has no database of its own (no migrations); it reads death-valley's, so all of its
  widgets can be rebuilt from the copy.
- `../beginly-admin`: Command, the internal admin tool. Its `beginly` connection reads death-valley's database, so those
  queries port directly. Its default connection is its own database (`beginly-admin-prod`: Command users, roles, sessions),
  which is NOT in the analytics copy.

Put finished SQL in `queries/`, one file per question or model, with a comment header saying what it answers.

### Data traps (death-valley schema)

- `users.first_name` / `last_name` are often empty; build names from `users.name`.
- `resident_programs.program_type` needs a `LIKE` match; equality matches nothing.
- Spatie tag names are translatable JSON; never compare `tags.name` as plain text.
- `formal_name` is stale and always says "Dr."; don't display it.
- `location_preferences.rating <= 5` means the state is excluded.
- `user_insights_cache` and `user_statistics_cache` are stale; compute from source tables.
- `analytics_all_candidates` is a view over `users`.

## Infrastructure (AWS us-west-2, VPC `vpc-09d43a1bd31e9b8ee`)

| Piece | ID |
| --- | --- |
| Analytics clone | cluster `beginly-analytics`, instance `beginly-analytics-1` (Serverless v2 0–4 ACU, private) |
| Clone endpoint | `beginly-analytics.cluster-cxam43dpp1ju.us-west-2.rds.amazonaws.com`, db `beginlydemo` |
| Source | `beginlyproduction-cluster` (Aurora PG 14.20) |
| Metabase server | EC2 `i-0a431e12387d827cd` (t4g.medium, AL2023 arm64), containers `metabase` + `metabase-db` |
| Security groups | `sg-0dc251d2ca4a7ff63` (server, no inbound), `sg-00a2d740343c1413c` (clone, 5432 from server only) |
| IAM role | `beginly-metabase-instance`: SSM core + `BeginlyAnalyticsSecrets` + `BeginlyAnalyticsNightlyRefresh` (`infra/iam-nightly-refresh-policy.json`) + `BeginlyAlertsPublish` |
| Secrets | `beginly/analytics/master`, `beginly/analytics/reader` |
| Backups | DLM `policy-02f2ba68e20d2e821`: daily 09:00 UTC snapshot of volumes tagged `Backup=metabase` (`vol-0c2d4002d61d325ed`), keeps 7, role `AWSDataLifecycleManagerDefaultRole` |
| Alerts | SNS `beginly-cost-alerts` (email) |
| Tailscale | tailnet `tailbbd43a`, device `beginly-metabase` (`tag:metabase`), `tailscale serve --bg 3000` |

Nightly at 10:00 UTC, `refresh.sh` deletes the clone, re-clones prod, sets the clone's own master password,
then `scrub-and-grant.sh` removes credentials and creates the read-only `metabase_reader` login last (fails closed).
A failed run emails the alert topic via `notify-failure.sh`.

### Changing the server

The server has no SSH. Run commands through SSM from CloudShell. CloudShell mangles multi-line pastes, so send
scripts as base64:

```bash
B64='<base64 of the script>' && CID=$(aws ssm send-command --region us-west-2 --no-cli-pager --instance-ids i-0a431e12387d827cd --document-name AWS-RunShellScript --parameters "commands=[\"echo $B64 | base64 -d | bash\"]" --query Command.CommandId --output text) && sleep 10 && aws ssm get-command-invocation --region us-west-2 --no-cli-pager --command-id $CID --instance-id i-0a431e12387d827cd --query '[Status,StandardOutputContent,StandardErrorContent]' --output text
```

Box paths: scripts in `/opt/metabase/bin/`, units in `/etc/systemd/system/` (`alert.conf` goes in
`beginly-analytics-refresh.service.d/`).
