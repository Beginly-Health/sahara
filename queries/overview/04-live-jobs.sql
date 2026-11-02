-- Beginly Overview: how many jobs are live right now?
-- Display: Number
-- Runs lower than Command's Active Jobs tile on purpose: that tile also counts deleted jobs
-- and jobs past their close date. Our own General Hospital's jobs are left out by ID, because a client shares the name.

SELECT COUNT(*) AS live_jobs
FROM opportunities
WHERE status = 'published'
  AND publish_date <= now()
  AND deleted_at IS NULL
  AND (close_date IS NULL OR close_date >= CURRENT_DATE)
  AND employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5';
