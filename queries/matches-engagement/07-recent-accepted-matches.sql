-- Matches & Engagement: who accepted a match in the last 30 days?
-- Display: Table
-- One row per accepted match, newest first, like Command's Accepted Matches page. Same columns as the
-- Daily Acquisition matches card. Leaves out General Hospital's jobs (by ID), staff and super admins.
-- candidate_accept_date is stored without a zone, in UTC.

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
JOIN users u ON u.id = om.user_id
JOIN opportunities o ON o.id = om.opportunity_id
LEFT JOIN employers e ON e.id = o.employer_id
WHERE om.deleted_at IS NULL
  AND om.candidate_reply_status = 'match_accepted'
  AND (om.candidate_accept_date AT TIME ZONE 'UTC') >= now() - INTERVAL '30 days'
  AND o.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
  AND u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us'
ORDER BY om.candidate_accept_date DESC;
