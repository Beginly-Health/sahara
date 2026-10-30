-- Beginly Overview: how many of those candidates are actively looking?
-- Display: Number
-- Matches Command's Active Job Seekers tile.

SELECT COUNT(*) AS active_job_seekers
FROM users
WHERE intro_complete = true
  AND active_job_seeking = true
  AND deleted_at IS NULL
  AND recruiter = false
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us';
