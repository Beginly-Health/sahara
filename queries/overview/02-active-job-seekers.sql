-- Beginly Overview: how many active candidates are looking for work?
-- Display: Number
-- Total active candidates with the seeking flag on who finished onboarding. The flag defaults to on at signup.
-- Runs lower than Command's Active Job Seekers tile: intro_complete is set at first login, so that tile also
-- counts people who stopped partway or have no onboarding step.

SELECT COUNT(*) AS active_candidates_seeking_jobs
FROM users
WHERE recruiter = false
  AND adminsales IS NOT TRUE
  AND deleted_at IS NULL
  AND active_job_seeking = true
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us'
  AND onboarding_step = 'Complete';