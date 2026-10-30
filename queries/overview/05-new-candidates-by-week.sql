-- Beginly Overview: how many new candidates sign up each week?
-- Display: Line (x = week, y = new_candidates)
-- Last 12 months of complete weeks, by account creation date. The current week is left out so the
-- line doesn't dip at the end.

SELECT
    date_trunc('week', created_at)::date AS week,
    COUNT(*) AS new_candidates
FROM users
WHERE intro_complete = true
  AND deleted_at IS NULL
  AND recruiter = false
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us'
  AND created_at >= date_trunc('week', now() - INTERVAL '12 months')
  AND created_at < date_trunc('week', now())
GROUP BY 1
ORDER BY 1;
