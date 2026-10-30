-- Beginly Overview: how many real candidates have finished signup?
-- Display: Number
-- Matches Command's Total Candidates tile: staff, recruiter and test accounts are excluded.

SELECT COUNT(*) AS candidates
FROM users
WHERE intro_complete = true
  AND deleted_at IS NULL
  AND recruiter = false
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us';
