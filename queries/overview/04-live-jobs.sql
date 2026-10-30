-- Beginly Overview: how many jobs are live right now?
-- Display: Number
-- Runs lower than Command's Active Jobs tile on purpose: that tile also counts deleted jobs
-- and jobs past their close date.

SELECT COUNT(*) AS live_jobs
FROM opportunities
WHERE status = 'published'
  AND deleted_at IS NULL
  AND (close_date IS NULL OR close_date >= CURRENT_DATE);
