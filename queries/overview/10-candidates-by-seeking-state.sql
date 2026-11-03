-- Beginly Overview: which states do candidates want to work in?
-- Display: Map > Region map > United States (region = state, metric = candidates)
-- Active candidates seeking jobs who rate each state above 5, so one candidate counts in every state they'd
-- work in. Command's state heat map counts every rating above 6 from everyone, including staff and deleted
-- accounts, so it reads differently. A rating of 5 or under means the candidate excluded the state.

SELECT
    upper(lp.state) AS state,
    COUNT(DISTINCT u.id) AS candidates
FROM location_preferences lp
JOIN users u ON u.id = lp.user_id
WHERE lp.deleted_at IS NULL
  AND lp.rating > 5
  AND lp.state IS NOT NULL
  AND lp.state <> ''
  AND u.deleted_at IS NULL
  AND u.active_job_seeking = true
  AND u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us'
GROUP BY 1
ORDER BY candidates DESC;
