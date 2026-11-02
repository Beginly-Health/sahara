-- Daily Acquisition: which candidates accepted a match in the report window?
-- Display: Table
-- The "New Matches" half of death-valley's daily #user-acquisition post (UserAcquisitionReportService),
-- one row per accepted match, oldest first. Same window as the post: the 24 hours ending at the most
-- recent 08:30 Eastern, by when the candidate accepted. Set Report date to see an earlier day's window.
-- Variable: report_date (Date, optional). Wire it to the dashboard's date filter.
-- Unlike the post, leaves out General Hospital's jobs (by ID) and super admins, per Sahara's rules.
-- candidate_accept_date is stored without a zone, in UTC.

WITH report_window AS (
    SELECT
        (window_end_local - INTERVAL '1 day') AT TIME ZONE 'America/New_York' AS window_start,
        window_end_local AT TIME ZONE 'America/New_York' AS window_end
    FROM (
        SELECT COALESCE(
            [[{{report_date}}::date + TIME '08:30',]]
            date_trunc('day', (now() AT TIME ZONE 'America/New_York') - INTERVAL '8 hours 30 minutes')
                + INTERVAL '8 hours 30 minutes'
        ) AS window_end_local
    ) AS latest
)
SELECT
    om.candidate_accept_date AT TIME ZONE 'UTC' AS accepted_at,
    u.name AS candidate,
    COALESCE(NULLIF(replace(replace(u.source, '_', ' '), '-', ' '), ''), 'direct') AS source,
    COALESCE(NULLIF(o.title, ''), 'Untitled job') AS job,
    e.name AS employer,
    (
        SELECT NULLIF(concat_ws(', ', NULLIF(a.city, ''), NULLIF(a.state, '')), '')
        FROM addresses a
        WHERE a.addressable_type = 'App\Models\EmployerBranch'
          AND a.addressable_id = o.employer_branch_id
          AND a.deleted_at IS NULL
        ORDER BY a.created_at
        LIMIT 1
    ) AS location
FROM opportunity_matches om
CROSS JOIN report_window rw
JOIN users u ON u.id = om.user_id
JOIN opportunities o ON o.id = om.opportunity_id
LEFT JOIN employers e ON e.id = o.employer_id
WHERE om.deleted_at IS NULL
  AND om.candidate_reply_status = 'match_accepted'
  AND om.candidate_accept_date BETWEEN (rw.window_start AT TIME ZONE 'UTC') AND (rw.window_end AT TIME ZONE 'UTC')
  AND o.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
  AND u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us'
ORDER BY om.candidate_accept_date;
