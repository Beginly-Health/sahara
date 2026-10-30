-- Beginly Overview: are candidates responding to their matches?
-- Display: Stacked bar (x = week, series = response, y = matches)
-- Last 12 months of complete weeks, by the date of the candidate's action. A match counts in its
-- latest accepted or declined state, and also as saved if it was ever saved, so weeks don't sum to
-- unique matches. Deleted matches (including removed duplicates) are left out.

WITH matches AS (
    SELECT om.candidate_accept_date, om.candidate_decline_date, om.saved_at
    FROM opportunity_matches om
    JOIN users u ON u.id = om.user_id
    WHERE om.deleted_at IS NULL
      AND u.deleted_at IS NULL
      AND u.recruiter = false
      AND u.email NOT ILIKE '%@beginlyhealth.com'
      AND u.email NOT ILIKE '%@generalhospital.us'
),
responses AS (
    SELECT candidate_accept_date AS responded_at, 'Accepted' AS response FROM matches
    UNION ALL
    SELECT saved_at, 'Saved' FROM matches
    UNION ALL
    SELECT candidate_decline_date, 'Declined' FROM matches
)
SELECT
    date_trunc('week', responded_at)::date AS week,
    response,
    COUNT(*) AS matches
FROM responses
WHERE responded_at >= date_trunc('week', now() - INTERVAL '12 months')
  AND responded_at < date_trunc('week', now())
GROUP BY 1, 2
ORDER BY 1, 2;
