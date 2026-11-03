-- Employers & Jobs: which employers have the most live jobs?
-- Display: Bar (x = employer, y = live_jobs) or Table
-- Top 20 active employers by live jobs, with their locations and total jobs for context. Without our own
-- General Hospital (by ID). Can also be built in the query builder from the Employers model.

SELECT
    name AS employer,
    live_opportunity_count AS live_jobs,
    branch_count AS locations,
    total_opportunity_count AS total_jobs
FROM (
    SELECT
        e.name,
        (
            SELECT COUNT(*)
            FROM opportunities o
            WHERE o.employer_id = e.id
              AND o.status = 'published'
              AND o.publish_date <= now()
              AND o.deleted_at IS NULL
              AND (o.close_date IS NULL OR o.close_date >= CURRENT_DATE)
        ) AS live_opportunity_count,
        (
            SELECT COUNT(*)
            FROM employer_branches b
            WHERE b.employer_id = e.id
              AND b.deleted_at IS NULL
        ) AS branch_count,
        (
            SELECT COUNT(*)
            FROM opportunities o
            WHERE o.employer_id = e.id
              AND o.deleted_at IS NULL
        ) AS total_opportunity_count
    FROM employers e
    WHERE e.deleted_at IS NULL
      AND e.id <> '01hbbc903rmz2pv9fgegy1qxp5'
) AS employer_counts
WHERE live_opportunity_count > 0
ORDER BY live_opportunity_count DESC, name
LIMIT 20;
