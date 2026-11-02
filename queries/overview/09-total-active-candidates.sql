-- Beginly Overview: how many registered candidates still have an account?
-- Display: Number
-- Total candidates minus deleted accounts. Includes people still in onboarding.

SELECT COUNT(*) AS total_active_candidates
FROM users
WHERE recruiter = false
  AND adminsales IS NOT TRUE
  AND deleted_at IS NULL
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us';
