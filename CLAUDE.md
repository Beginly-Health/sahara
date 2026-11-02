# Sahara: Beginly Analytics

Home of Beginly's internal reporting: a self-hosted Metabase over a nightly, scrubbed copy of the
death-valley production database. This repo holds the infrastructure scripts and the SQL the team's
dashboards are built from. It is not an application; nothing here deploys automatically.

- ClickUp: Data Warehouse `86ajzu37e`
- Team guide + admin runbook: https://claude.ai/artifact/MUZoqwd6teMWiFmGGEAooS (keep it current when the setup changes)
- Metabase: https://beginly-metabase.tailbbd43a.ts.net (Beginly Tailscale network only)

## Rules

- **Security first.** Metabase has no inbound ports; access is Tailscale only. Don't propose public exposure.
- **Claude Code never connects to the data.** It reads code and schemas and writes SQL; people run it in Metabase.
- **Metabase's AI runs only on Claude through Amazon Bedrock**, under Beginly's AWS account. Kristi approved this for
  production data on 2026-11-01. Any other provider or AI access to the data needs its own approval.
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

### Who counts as a candidate

Each level narrows the one above:

- **Total Candidates:** everyone ever registered: `users.recruiter = false`, `adminsales` not true (super admins, who never count in
  any report; it can be null), and email not `@beginlyhealth.com` or `@generalhospital.us`. Includes deleted accounts and people still in onboarding. Don't require the `candidate` role:
  494 active, seeking candidates from 2024 and 2025 hold no role at all (checked on prod, 2026-11-01).
- **Total Active Candidates:** Total Candidates with `deleted_at IS NULL`.
- **Active Candidates Seeking Jobs:** Total Active Candidates with `active_job_seeking = true`. Candidates can turn this off.

`onboarding_step = 'Complete'` means they finished onboarding; apply it only when a question asks for that. Use it,
not `intro_complete`.

### Employers, jobs and matches

- **Active Employer:** `deleted_at IS NULL`. `employers.status` has no meaning today; don't filter on it.
- **Live Job:** `status = 'published'`, `publish_date <= now()`, not deleted, and `close_date` is null or today or later.
- **Accepted Match:** `candidate_reply_status = 'match_accepted'`. A candidate can only accept, save or decline, and any
  of the three counts as engagement. Saved also requires `saved_at IS NOT NULL`, as in carcross.
- **General Hospital** is Beginly's own employer and may hold test jobs. Leave it out of employer, job and match reporting
  by ID, `01hbbc903rmz2pv9fgegy1qxp5`, never by name: a client shares the name.

### Metabase models

The team builds its own questions and dashboards on models rather than on the saved queries. `queries/models/` holds
each model's SQL and `glossary.md`, in step with Metabase. Rules go in the model, so nobody has to remember them.

Metabase's report timezone is `America/Los_Angeles` (US Pacific), so "yesterday" means a US Pacific day. Not
`America/Vancouver`: BC stopped changing its clocks, so the two differ by an hour in winter.

The Daily Acquisition dashboard (`queries/acquisition/`) uses the window of death-valley's daily #user-acquisition
post: the 24 hours ending 08:30 Eastern. The nightly copy stops at 10:00 UTC, so a person who signs up or accepts
between then and 08:30 Eastern shows on the next day's refresh. Checked against the 2026-11-01 post.

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
| Analytics clone | cluster `beginly-analytics`, instance `beginly-analytics-1` (Serverless v2 0–4 ACU, private; pauses after 1 hour idle and takes ~15 s to wake, so Metabase's connection sets `connectTimeout=60`) |
| Clone endpoint | `beginly-analytics.cluster-cxam43dpp1ju.us-west-2.rds.amazonaws.com`, db `beginlydemo` |
| Source | `beginlyproduction-cluster` (Aurora PG 14.20) |
| Metabase server | EC2 `i-0a431e12387d827cd` (t4g.medium, AL2023 arm64), containers `metabase` + `metabase-db` |
| Security groups | `sg-0dc251d2ca4a7ff63` (server, no inbound), `sg-00a2d740343c1413c` (clone, 5432 from server only) |
| IAM role | `beginly-metabase-instance`: SSM core + `BeginlyAnalyticsSecrets` + `BeginlyAnalyticsNightlyRefresh` (`infra/iam-nightly-refresh-policy.json`) + `BeginlyAlertsPublish` + `BeginlyMetabaseBedrockInference` (`infra/iam-bedrock-policy.json`) |
| Secrets | `beginly/analytics/master`, `beginly/analytics/reader` |
| Backups | DLM `policy-02f2ba68e20d2e821`: daily 09:00 UTC snapshot of volumes tagged `Backup=metabase` (`vol-0c2d4002d61d325ed`), keeps 7, role `AWSDataLifecycleManagerDefaultRole` |
| Alerts | SNS `beginly-cost-alerts` (email; topic policy lets AWS Budgets publish). Budget `bedrock-ai-monthly`: $50/month on Claude via Bedrock, alerts at 50%, 100% and forecast over |
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
