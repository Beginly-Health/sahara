# Project Context

> Living document. Updated at the end of each coding session via `/session-end`.
> See `CLAUDE.md` for stable rules, definitions and infrastructure.
> This file is tool-agnostic and readable by any AI assistant.

---

## Architecture Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-11-01 | The team self-serves on Metabase Models plus the glossary, not on saved queries | Rules live in the model, so people and Metabot get them without remembering them |
| 2026-11-01 | Models are built from the schema on death-valley's `main` and the apps' Eloquent logic, not from the dev database or raw data | Dev carries unmerged migrations (e.g. `employers.source`, `is_external`), and raw data hides intent |
| 2026-11-01 | Metabot runs on Claude Haiku 4.5 through Amazon Bedrock (`us-west-2`), via the server's IAM role, no keys | Kristi approved this setup for production data; keeps data inside Beginly's AWS account |
| 2026-11-01 | Stay on the free edition of Metabase | Paid adds Metabot controls and sandboxing, but nothing that guarantees better answers |
| 2026-11-02 | Report timezone `America/Los_Angeles`, not `America/Vancouver` | Beginly is a US West Coast business; BC stopped changing clocks, so the two now differ by an hour in winter |
| 2026-11-02 | Clone pauses after 1 hour idle (`SecondsUntilAutoPause=3600` in `refresh.sh`) and Metabase uses `connectTimeout=60` | The 5-minute default meant most questions hit a ~15 s cold start, which outlasted Metabase's 10 s connect timeout |

---

## Known Gotchas

- `opportunity_matches.candidate_accept_date` (and the other match dates) are `timestamp` without zone, written in UTC. Compare with `(some_timestamptz AT TIME ZONE 'UTC')`. `users.created_at` is `timestamptz`.
- In Postgres, `x BETWEEN a AT TIME ZONE 'UTC' AND b ...` is a syntax error; wrap each side in parentheses.
- The nightly copy stops at 10:00 UTC. Anything after that (e.g. the last hours of the Slack acquisition window, which ends 08:30 Eastern) shows up a day late.
- In Metabase, a question saved into a dashboard belongs to that dashboard only. Save to a collection to reuse it on several dashboards.
- Metabase only fills blank descriptions from Postgres `COMMENT ON` (issue #70029).
- Metabase sends the report timezone to Postgres, so it decides "yesterday" and date grouping everywhere, not just display.
- Weekly overview charts (`05`, `06`) label each point with the week's Monday and leave out the current week, so on a Monday the newest point is last Monday.
- The Bedrock "access denied" error for Claude can mean the Anthropic agreement isn't accepted for the account; the message doesn't say so. Usage is in CloudWatch under `AWS/BedrockMantle`, in the console's classic view.

---

## Established Patterns

- Optional Metabase date variable that falls back to a computed default: `COALESCE([[{{report_date}}::date + TIME '08:30',]] <default>)`. Metabase drops the bracketed text when the variable is empty.
- Check new SQL in a throwaway `postgres:16-alpine` container with stub tables, never against Beginly data.
- Verify a dashboard card against the source it replaces (e.g. the Slack post) row by row before calling it done.
- Server changes: edit the script here, commit, then install it on the box via the SSM base64 command in `CLAUDE.md`, checking the box's AWS CLI supports any new flag first.

---

## Open Questions

- [ ] Should Active Candidates Seeking Jobs (`is_seeking_jobs` in the Candidates model) require finished onboarding? Query `02` already does; the model and glossary don't.
- [ ] Switch the Daily Acquisition queries to the US Pacific calendar day (midnight to midnight, default yesterday). Agreed in principle once the Slack post is retired; not changed yet.
- [ ] Confirm Metabase's report timezone is set to `America/Los_Angeles`.
- [ ] Confirm the 2026-11-02 refresh finished with the new `refresh.sh`.
- [ ] Set an AWS spending alert to `beginly-cost-alerts` before the team gets Metabot.
- [ ] Delete IAM user `beginly-metabase-bedrock-local` when local Bedrock testing ends.
- [ ] Update the team guide (https://claude.ai/artifact/MUZoqwd6teMWiFmGGEAooS) for Models, Metabot, the timezone and Daily Acquisition.
- [ ] Later: Metrics, segments, SQL snippets, model foreign keys, and table descriptions via a death-valley migration.
