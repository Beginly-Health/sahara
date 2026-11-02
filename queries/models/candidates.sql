-- Metabase model: Candidates. Start here for any candidate question.
-- Display: Model (New > Model > Use a native query)
    -- Everyone ever registered as a candidate, with staff and recruiters removed. Includes deleted accounts.
-- Use is_active for active candidates and is_seeking_jobs for active candidates seeking jobs.
-- Names and emails are left out so Metabot has less personal data to read.

SELECT
    id,
    created_at,
    source,
    onboarding_step,
    deleted_at IS NULL AS is_active,
    deleted_at IS NULL AND active_job_seeking AS is_seeking_jobs,
    onboarding_step = 'Complete' AS finished_onboarding
FROM users
WHERE recruiter = false
  AND adminsales IS NOT TRUE
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us'
