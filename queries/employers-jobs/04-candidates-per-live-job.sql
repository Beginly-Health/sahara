-- Employers & Jobs: how many candidates are looking for each live job?
-- Display: Number (one decimal)
-- Active candidates seeking jobs divided by live jobs. Above 1 means more candidates than jobs.
-- Command reads its ratio from analytics_ratios, which uses its own definitions; this uses Sahara's.

SELECT ROUND(
    (
        SELECT COUNT(*)
        FROM users
        WHERE recruiter = false
          AND adminsales IS NOT TRUE
          AND deleted_at IS NULL
          AND active_job_seeking = true
          AND email NOT ILIKE '%@beginlyhealth.com'
          AND email NOT ILIKE '%@generalhospital.us'
    )::numeric
    / NULLIF((
        SELECT COUNT(*)
        FROM opportunities
        WHERE status = 'published'
          AND publish_date <= now()
          AND deleted_at IS NULL
          AND (close_date IS NULL OR close_date >= CURRENT_DATE)
          AND employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
    ), 0),
    1
) AS candidates_per_live_job;
