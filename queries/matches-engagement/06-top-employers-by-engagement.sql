-- Matches & Engagement: which employers' jobs do candidates respond to most?
-- Display: Table, or Bar (x = employer, y = accepted, saved, declined)
-- Top 20 active employers by engaged matches (accepted, saved or declined), with each response and the
-- share of their matches that got one. Matches to active candidates only, General Hospital left out (by ID).

SELECT
    e.name AS employer,
    COUNT(*) AS matches,
    COUNT(*) FILTER (WHERE om.candidate_reply_status = 'match_accepted') AS accepted,
    COUNT(*) FILTER (WHERE om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL) AS saved,
    COUNT(*) FILTER (WHERE om.candidate_reply_status = 'declined') AS declined,
    COUNT(*) FILTER (
        WHERE om.candidate_reply_status IN ('match_accepted', 'declined')
           OR (om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL)
    ) AS engaged,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE om.candidate_reply_status IN ('match_accepted', 'declined')
               OR (om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL)
        ) / COUNT(*),
        1
    ) AS engagement_rate_pct
FROM opportunity_matches om
JOIN users u ON u.id = om.user_id
JOIN employers e ON e.id = om.employer_id
WHERE om.deleted_at IS NULL
  AND e.deleted_at IS NULL
  AND e.id <> '01hbbc903rmz2pv9fgegy1qxp5'
  AND u.deleted_at IS NULL
  AND u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us'
GROUP BY e.id, e.name
ORDER BY engaged DESC, e.name
LIMIT 20;
