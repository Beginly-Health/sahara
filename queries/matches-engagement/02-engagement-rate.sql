-- Matches & Engagement: what share of matches do candidates respond to?
-- Display: Number (percent, one decimal)
-- Engaged matches (accepted, saved or declined) as a percent of all matches to active candidates.
-- Same matches as 01-candidate-responses, so it equals (Accepted + Saved + Declined) / all of 01.

SELECT ROUND(
    100.0 * COUNT(*) FILTER (
        WHERE om.candidate_reply_status = 'match_accepted'
           OR (om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL)
           OR om.candidate_reply_status = 'declined'
    ) / NULLIF(COUNT(*), 0),
    1
) AS engagement_rate_pct
FROM opportunity_matches om
JOIN users u ON u.id = om.user_id
WHERE om.deleted_at IS NULL
  AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
  AND u.deleted_at IS NULL
  AND u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us';
