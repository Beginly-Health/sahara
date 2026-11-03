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
| 2026-11-02 | One Bedrock budget for now (`bedrock-ai-monthly`, $50/month); per-app budgets by tag once death-valley and carcross move from OpenAI to Bedrock | AWS bills Bedrock by model, not caller; tagged application inference profiles are the way to split it |
| 2026-11-02 | Local Metabot testing uses Ollama on `atlas`; no AWS keys for local Metabase | The test IAM user was deleted; the team server uses its role |
| 2026-11-03 | Metabase layout: collections Reports (Daily Acquisition, the home page; Weekly Measurements), Candidates (Candidates Overview, Profile questions tab), Employers and Jobs (Employers and Jobs tabs), Matches and Engagement, Beginly Health Data Models. There is no Beginly Overview dashboard; `queries/overview/` cards live on the subject dashboards | Bryan's layout: scheduled reports apart from subject dashboards, models in one place |
| 2026-11-03 | Stop porting Command for now; the team decides what comes next | Enough is built to prove the system. Staying in Command: incomplete registrations, temporary profiles, scoring. Rejected: a live jobs list, candidates vs jobs by state, answers by week. Later: Dropped Balls (incomplete in Command) |
| 2026-11-03 | Weekly Measurements is rebuilt from source tables, not Command's `get_weekly_user_activity_report` | That function reads trigger-fed summary tables. Activations = finished onboarding (Command: 6 answers or a referral); Match Requests dropped (employers can't start matches); WAU/MAU still come from `user_activity_metrics`, the only login history |
| 2026-11-03 | Ratio cards use the exact definitions of the tiles beside them (e.g. live jobs per employer = `overview/04` / `overview/03`) | Numbers on one dashboard must reconcile |
| 2026-11-03 | Team docs (Getting started guide, self-guided tour) are shared as Google Drive copies Bryan exports; edits happen in Claude Docs, then he re-exports | He doesn't want to share from Claude Docs |

---

## Known Gotchas

- Claude on Bedrock bills through AWS Marketplace as "Claude Haiku 4.5 (Amazon Bedrock Edition)", not "Amazon Bedrock". Budget `bedrock-ai-monthly` filters on both names; a new Claude model brings a new billing name that must be added to it.
- AWS bills Bedrock by model, not by caller. To split spend per app, give each app an application inference profile with a tag and filter on the tag.
- `opportunity_matches.candidate_accept_date` (and the other match dates) are `timestamp` without zone, written in UTC. Compare with `(some_timestamptz AT TIME ZONE 'UTC')`. `users.created_at` is `timestamptz`.
- In Postgres, `x BETWEEN a AT TIME ZONE 'UTC' AND b ...` is a syntax error; wrap each side in parentheses.
- The nightly copy stops at 10:00 UTC. Anything after that (e.g. the last hours of the Slack acquisition window, which ends 08:30 Eastern) shows up a day late.
- In Metabase, a question saved into a dashboard belongs to that dashboard only. Save to a collection to reuse it on several dashboards.
- Metabase only fills blank descriptions from Postgres `COMMENT ON` (issue #70029).
- Metabase sends the report timezone to Postgres, so it decides "yesterday" and date grouping everywhere, not just display.
- Weekly overview charts (`05`, `06`) label each point with the week's Monday and leave out the current week, so on a Monday the newest point is last Monday.
- Command's `analytics_ratios` counts every `status = 'published'` job (deleted, closed and General Hospital included) and only intro-complete candidates, so its Candidates per Job reads lower than ours (0.4 vs 0.6 on 2026-11-03).
- Command's match counts filter `employer_reply_status NOT IN ('decline', 'withdrawn')`; the enum value is `declined`, so that filter excludes nothing.
- A Metabase Number card shows one column. Return a single value from every number query; Bryan found two-column results confusing.
- A Metabase bar chart with a numeric x-axis needs the X-axis scale set to Ordinal in the chart settings.
- Some profile questions only show to certain specialties (tags), so their share of all candidates runs low by design. death-valley lists questions by `relevance DESC, ordinal` (a string).
- `users.last_login` holds only the latest login, so past weekly or monthly active users can't be rebuilt; `user_activity_metrics` (daily snapshot, staff included) is the only history.
- The Bedrock "access denied" error for Claude can mean the Anthropic agreement isn't accepted for the account; the message doesn't say so. Usage is in CloudWatch under `AWS/BedrockMantle`, in the console's classic view.

---

## Established Patterns

- Optional Metabase date variable that falls back to a computed default: `COALESCE([[{{report_date}}::date + TIME '08:30',]] <default>)`. Metabase drops the bracketed text when the variable is empty.
- Check new SQL in a throwaway `postgres:16-alpine` container with stub tables, never against Beginly data.
- Verify a dashboard card against the source it replaces (e.g. the Slack post) row by row before calling it done.
- Each dashboard's queries go in their own folder (`employers-jobs/`, `matches-engagement/`, `weekly/`, `profile-questions/`) and their own PR, branched from `origin/main`, so PRs merge in any order.
- When porting a Command tile, read its query (often a death-valley view or function) and state in the file header how and why Sahara's number differs.
- Server changes: edit the script here, commit, then install it on the box via the SSM base64 command in `CLAUDE.md`, checking the box's AWS CLI supports any new flag first.

---

## Open Questions

- [ ] (Parked by Bryan, revisit only when he raises it) Should Active Candidates Seeking Jobs (`is_seeking_jobs` in the Candidates model) require finished onboarding? Query `02` already does; the model and glossary don't.
- [ ] To do: switch the Daily Acquisition queries to the US Pacific calendar day (midnight to midnight, default yesterday). Agreed in principle once the Slack post is retired; not changed yet.
- [x] [RESOLVED 2026-11-02] Report timezone set to `America/Los_Angeles`; refresh confirmed with the new `refresh.sh`.
- [x] [RESOLVED 2026-11-02] Budget `bedrock-ai-monthly` ($50/month) emails `beginly-cost-alerts` at 50%, 100% and forecast over 100%.
- [x] [RESOLVED 2026-11-02] Deleted test IAM user `beginly-metabase-bedrock-local`; local Metabase uses Ollama on `atlas` for Metabot testing.
- [x] [RESOLVED 2026-11-02] Team guide updated for Models, Metabot, the timezone, Daily Acquisition, the 1-hour pause and the Bedrock budget.
- [ ] Later: Metrics, segments, SQL snippets, model foreign keys, and table descriptions via a death-valley migration.
- [ ] The self-guided tour links to the Getting started guide by its private claude.ai URL. Point it at the guide's Google Drive link (Bryan to send) or drop the link before he exports the tour.
- [ ] Later, when Command's version is complete: Dropped Balls follow-up lists.
- [ ] Moving death-valley and carcross AI calls from OpenAI to Bedrock, with tagged application inference profiles for per-app spend.
- [x] [RESOLVED 2026-11-03] Tailscale "Tailworm" flaws: the Metabase server is on 1.104.4 (fixed); Serve is one TCP proxy, Tailscale SSH off, no Funnel. No team clients installed yet.
