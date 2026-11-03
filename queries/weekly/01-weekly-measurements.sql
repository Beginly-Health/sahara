-- Weekly Measurements: how did each of the last 12 weeks go?
-- Display: Table, newest week first. Each column also works as a line chart (x = week).
-- Command's Weekly Measurements page, rebuilt from source tables on Sahara's rules, one row per complete
-- US Pacific week (Monday to Sunday). Command's numbers come from trigger-fed summary tables and count
-- staff and General Hospital, so they read differently.
--   new_candidates: signups that week (Total Candidates, so accounts deleted since still count)
--   onboarded_since: how many of that week's signups have finished onboarding by now
--   match_views / saves / declines / accepts: candidate actions that week, by the action's date, on
--     matches to active candidates, without General Hospital's jobs (by ID). A match counts as saved
--     if it was ever saved, as in overview/06.
--   jobs_published: jobs that went live that week, by publish date, without General Hospital's
--   weekly_active_users / monthly_active_users: death-valley's own snapshot (user_activity_metrics), the
--     last one taken that week. It counts candidates who logged in in the 7 or 30 days before, staff included.
-- Command's "Match Requests" (employer-initiated matches) is left out: employers can no longer start one.
-- Match dates and publish_date are stored without a zone, in UTC.

WITH weeks AS (
    SELECT generate_series(
        date_trunc('week', now() AT TIME ZONE 'America/Los_Angeles') - INTERVAL '12 weeks',
        date_trunc('week', now() AT TIME ZONE 'America/Los_Angeles') - INTERVAL '1 week',
        INTERVAL '1 week'
    )::date AS week
),
signups AS (
    SELECT
        date_trunc('week', created_at AT TIME ZONE 'America/Los_Angeles')::date AS week,
        COUNT(*) AS new_candidates,
        COUNT(*) FILTER (WHERE onboarding_step = 'Complete') AS onboarded_since
    FROM users
    WHERE recruiter = false
      AND adminsales IS NOT TRUE
      AND email NOT ILIKE '%@beginlyhealth.com'
      AND email NOT ILIKE '%@generalhospital.us'
      AND created_at >= now() - INTERVAL '14 weeks'
    GROUP BY 1
),
matches AS (
    SELECT om.first_viewed_at, om.saved_at, om.candidate_decline_date, om.candidate_accept_date,
           om.candidate_reply_status
    FROM opportunity_matches om
    JOIN users u ON u.id = om.user_id
    WHERE om.deleted_at IS NULL
      AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
      AND u.deleted_at IS NULL
      AND u.recruiter = false
      AND u.adminsales IS NOT TRUE
      AND u.email NOT ILIKE '%@beginlyhealth.com'
      AND u.email NOT ILIKE '%@generalhospital.us'
),
actions AS (
    SELECT first_viewed_at AS acted_at, 'view' AS action FROM matches
    UNION ALL
    SELECT saved_at, 'save' FROM matches
    UNION ALL
    SELECT candidate_decline_date, 'decline' FROM matches WHERE candidate_reply_status = 'declined'
    UNION ALL
    SELECT candidate_accept_date, 'accept' FROM matches WHERE candidate_reply_status = 'match_accepted'
),
match_actions AS (
    SELECT
        date_trunc('week', (acted_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Los_Angeles')::date AS week,
        COUNT(*) FILTER (WHERE action = 'view') AS match_views,
        COUNT(*) FILTER (WHERE action = 'save') AS saves,
        COUNT(*) FILTER (WHERE action = 'decline') AS declines,
        COUNT(*) FILTER (WHERE action = 'accept') AS accepts
    FROM actions
    WHERE acted_at >= (now() AT TIME ZONE 'UTC') - INTERVAL '14 weeks'
    GROUP BY 1
),
jobs AS (
    SELECT
        date_trunc('week', (publish_date AT TIME ZONE 'UTC') AT TIME ZONE 'America/Los_Angeles')::date AS week,
        COUNT(*) AS jobs_published
    FROM opportunities
    WHERE status = 'published'
      AND deleted_at IS NULL
      AND employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
      AND publish_date >= (now() AT TIME ZONE 'UTC') - INTERVAL '14 weeks'
    GROUP BY 1
),
active_users AS (
    SELECT DISTINCT ON (1)
        date_trunc('week', created_at AT TIME ZONE 'America/Los_Angeles')::date AS week,
        weekly_active_users,
        monthly_active_users
    FROM user_activity_metrics
    WHERE created_at >= now() - INTERVAL '14 weeks'
    ORDER BY 1, created_at DESC
)
SELECT
    w.week,
    COALESCE(s.new_candidates, 0) AS new_candidates,
    COALESCE(s.onboarded_since, 0) AS onboarded_since,
    COALESCE(m.match_views, 0) AS match_views,
    COALESCE(m.saves, 0) AS saves,
    COALESCE(m.declines, 0) AS declines,
    COALESCE(m.accepts, 0) AS accepts,
    COALESCE(j.jobs_published, 0) AS jobs_published,
    a.weekly_active_users,
    a.monthly_active_users
FROM weeks w
LEFT JOIN signups s ON s.week = w.week
LEFT JOIN match_actions m ON m.week = w.week
LEFT JOIN jobs j ON j.week = w.week
LEFT JOIN active_users a ON a.week = w.week
ORDER BY w.week DESC;
