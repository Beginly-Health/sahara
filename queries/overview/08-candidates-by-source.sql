-- Beginly Overview: where did our candidates sign up from?
-- Display: Bar (x = source, y = candidates)
-- users.source mixes where someone signed up (public_job, opportunity-share, user_referral) with
-- who sent them (indeed, monkeyshines), so public_job does not mean a particular ad partner.
-- Uses the Total Candidates definition, so accounts deleted since still count. Command's Marketing
-- Sources widget covers active job seekers only.

SELECT
    COALESCE(NULLIF(source, ''), '(not recorded)') AS source,
    COUNT(*) AS candidates
FROM users
WHERE recruiter = false
  AND adminsales IS NOT TRUE
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us'
GROUP BY 1
ORDER BY 2 DESC;
