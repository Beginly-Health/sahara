-- Metabase model: Matches. Start here for any match or candidate engagement question.
-- Display: Model (New > Model > Use a native query)
-- One row per match between a candidate and an opportunity. Leaves out deleted matches (including removed duplicates),
-- staff and recruiters, and our own General Hospital's opportunities (by ID: a client shares the name). Accepted, saved and declined are the only things a candidate
-- can do, and is_engaged means any of them. Use these flags for "how many now". Use the date columns for trends.
-- is_interested is Carcross's Interested tile: accepted, and the employer hasn't declined or withdrawn.
-- Use candidate_is_active to limit to active candidates. Carcross only shows employers matches where
-- candidate_is_seeking_jobs is true, so add that filter to match what an employer sees there.

SELECT
    om.id,
    om.user_id AS candidate_id,
    om.opportunity_id,
    om.employer_id,
    e.name AS employer_name,
    om.score,
    om.candidate_reply_status,
    om.employer_reply_status,
    om.candidate_view_count,
    om.created_at,
    om.first_viewed_at,
    om.candidate_accept_date,
    om.candidate_decline_date,
    om.saved_at,
    om.candidate_reply_status = 'match_accepted' AS is_accepted,
    COALESCE(
        om.candidate_reply_status = 'match_accepted'
            AND om.employer_reply_status NOT IN ('declined', 'withdrawn'),
        false
    ) AS is_interested,
    om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL AS is_saved,
    om.candidate_reply_status = 'declined' AS is_declined,
    om.candidate_reply_status = 'match_accepted'
        OR (om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL)
        OR om.candidate_reply_status = 'declined' AS is_engaged,
    u.deleted_at IS NULL AS candidate_is_active,
    u.active_job_seeking AS candidate_is_seeking_jobs
FROM opportunity_matches om
JOIN users u ON u.id = om.user_id
LEFT JOIN employers e ON e.id = om.employer_id
WHERE om.deleted_at IS NULL
  AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
  AND u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us'
