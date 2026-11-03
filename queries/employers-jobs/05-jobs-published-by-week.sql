-- Employers & Jobs: how many new jobs go live each week?
-- Display: Line or Bar (x = week, y = jobs_published)
-- Jobs by the week their publish date falls in, last 12 months of complete weeks, without deleted jobs or
-- our own General Hospital's (by ID). Counts jobs that have since closed. publish_date is stored in UTC
-- without a zone; weeks are US Pacific. The current week is left out so the line doesn't dip at the end.

SELECT
    date_trunc('week', (publish_date AT TIME ZONE 'UTC') AT TIME ZONE 'America/Los_Angeles')::date AS week,
    COUNT(*) AS jobs_published
FROM opportunities
WHERE status = 'published'
  AND deleted_at IS NULL
  AND employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
  AND (publish_date AT TIME ZONE 'UTC') >= date_trunc('week', now() AT TIME ZONE 'America/Los_Angeles' - INTERVAL '12 months') AT TIME ZONE 'America/Los_Angeles'
  AND (publish_date AT TIME ZONE 'UTC') < date_trunc('week', now() AT TIME ZONE 'America/Los_Angeles') AT TIME ZONE 'America/Los_Angeles'
GROUP BY 1
ORDER BY 1;
