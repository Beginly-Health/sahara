-- Beginly Overview: how many candidates have ever registered?
-- Display: Number
-- Includes deleted accounts and people still in onboarding. Excludes recruiters and our own domains.
-- Differs from Command's Total Candidates tile, which is limited to intro_complete and not deleted.

SELECT COUNT(*) AS total_candidates
FROM users
WHERE recruiter = false
  AND adminsales IS NOT TRUE
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us';
