-- Beginly Overview: where did our candidates sign up from?
-- Display: Bar (x = source, y = candidates)
-- users.source mixes where someone signed up (public_job, opportunity-share, user_referral) with
-- who sent them (indeed, monkeyshines), so public_job does not mean a particular ad partner.
-- Covers all candidates; Command's Marketing Sources widget covers active job seekers only.

SELECT
    COALESCE(NULLIF(source, ''), '(not recorded)') AS source,
    COUNT(*) AS candidates
FROM users
WHERE intro_complete = true
  AND deleted_at IS NULL
  AND recruiter = false
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us'
GROUP BY 1
ORDER BY 2 DESC;
