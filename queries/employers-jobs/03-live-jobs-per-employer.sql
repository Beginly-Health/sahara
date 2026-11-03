-- Employers & Jobs: how many live jobs does an employer have, on average?
-- Display: Number (one decimal)
-- Live Jobs (overview/04) divided by Active Employers (overview/03), so it reconciles with those two tiles.
-- Without our own General Hospital (by ID).
-- Runs lower than Command's Average Jobs per Employer: that tile counts every job that isn't deleted,
-- including drafts and closed ones.

SELECT ROUND(
    (
        SELECT COUNT(*)
        FROM opportunities
        WHERE status = 'published'
          AND publish_date <= now()
          AND deleted_at IS NULL
          AND (close_date IS NULL OR close_date >= CURRENT_DATE)
          AND employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
    )::numeric
    / NULLIF((
        SELECT COUNT(*)
        FROM employers
        WHERE deleted_at IS NULL
          AND id <> '01hbbc903rmz2pv9fgegy1qxp5'
    ), 0),
    1
) AS live_jobs_per_employer;
