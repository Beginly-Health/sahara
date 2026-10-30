-- Beginly Overview: where do we have candidates without jobs, or jobs without candidates?
-- Display: Table, or Bar (x = specialty, y = candidates and live_jobs)
-- Built from source tables, not analytics_specialty_count: its job side only keeps jobs with no close
-- date or a past one, so it drops jobs that are still open. A candidate or job with several
-- specialties counts once in each.

WITH specialty_question AS (
    SELECT '01gy38dysqnmd06nrh85wdzdnz'::text AS id
),
candidate_specialties AS (
    SELECT
        json_array_elements_text(uq.value::json) AS specialty,
        uq.user_id
    FROM user_questions uq
    JOIN users u ON u.id = uq.user_id
    WHERE uq.question_id = (SELECT id FROM specialty_question)
      AND uq.deleted_at IS NULL
      AND u.intro_complete = true
      AND u.deleted_at IS NULL
      AND u.recruiter = false
      AND u.email NOT ILIKE '%@beginlyhealth.com'
      AND u.email NOT ILIKE '%@generalhospital.us'
),
job_specialties AS (
    SELECT
        json_array_elements_text(rq.value::json) AS specialty,
        rq.opportunity_id
    FROM recruiter_questions rq
    JOIN opportunities o ON o.id = rq.opportunity_id
    WHERE rq.question_id = (SELECT id FROM specialty_question)
      AND rq.deleted_at IS NULL
      AND o.status = 'published'
      AND o.deleted_at IS NULL
      AND (o.close_date IS NULL OR o.close_date >= CURRENT_DATE)
),
candidate_counts AS (
    SELECT specialty, COUNT(DISTINCT user_id) AS candidates
    FROM candidate_specialties
    GROUP BY specialty
),
job_counts AS (
    SELECT specialty, COUNT(DISTINCT opportunity_id) AS live_jobs
    FROM job_specialties
    GROUP BY specialty
)
SELECT
    COALESCE(c.specialty, j.specialty) AS specialty,
    COALESCE(c.candidates, 0) AS candidates,
    COALESCE(j.live_jobs, 0) AS live_jobs
FROM candidate_counts c
FULL OUTER JOIN job_counts j ON j.specialty = c.specialty
ORDER BY COALESCE(c.candidates, 0) + COALESCE(j.live_jobs, 0) DESC;
