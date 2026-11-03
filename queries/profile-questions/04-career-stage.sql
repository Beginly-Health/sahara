-- Profile questions: where are candidates in their careers?
-- Display: Pie or Bar (x = career_stage, y = candidates)
-- Active candidates by career stage (users.career_stage), with "Not set" for those without one.
-- Command's Career Stage Distribution widget, on Sahara's candidate rules.

SELECT
    COALESCE(initcap(replace(NULLIF(career_stage, ''), '_', ' ')), 'Not set') AS career_stage,
    COUNT(*) AS candidates
FROM users
WHERE deleted_at IS NULL
  AND recruiter = false
  AND adminsales IS NOT TRUE
  AND email NOT ILIKE '%@beginlyhealth.com'
  AND email NOT ILIKE '%@generalhospital.us'
GROUP BY 1
ORDER BY candidates DESC;
