-- Beginly Overview: where are the live jobs?
-- Display: Map > Region map > United States (region = state, metric = live_jobs)
-- Live jobs by the state of their location (the employer branch's first address, as death-valley reads it).
-- Without our own General Hospital (by ID). Jobs whose location has no state are left off the map.

SELECT
    upper(a.state) AS state,
    COUNT(*) AS live_jobs
FROM opportunities o
JOIN LATERAL (
    SELECT ad.state
    FROM addresses ad
    WHERE ad.addressable_type = 'App\Models\EmployerBranch'
      AND ad.addressable_id = o.employer_branch_id
      AND ad.deleted_at IS NULL
    ORDER BY ad.created_at
    LIMIT 1
) AS a ON true
WHERE o.status = 'published'
  AND o.publish_date <= now()
  AND o.deleted_at IS NULL
  AND (o.close_date IS NULL OR o.close_date >= CURRENT_DATE)
  AND o.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
  AND a.state IS NOT NULL
  AND a.state <> ''
GROUP BY 1
ORDER BY live_jobs DESC;
