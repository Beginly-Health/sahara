-- Profile questions: how many questions has each candidate answered?
-- Display: Bar (x = questions_answered, y = candidates). In the chart settings, set the X-axis scale to Ordinal.
-- Active candidates grouped by how many questions they've answered, from 0 up. A tall bar at 0 or 1 means
-- most people stop early. Uses the same answer rules as 01-answers-by-question.

WITH active_candidates AS (
    SELECT id
    FROM users
    WHERE deleted_at IS NULL
      AND recruiter = false
      AND adminsales IS NOT TRUE
      AND email NOT ILIKE '%@beginlyhealth.com'
      AND email NOT ILIKE '%@generalhospital.us'
),
per_candidate AS (
    SELECT
        c.id,
        COUNT(DISTINCT uq.question_id) AS questions_answered
    FROM active_candidates c
    LEFT JOIN user_questions uq
        ON uq.user_id = c.id
       AND uq.deleted_at IS NULL
       AND uq.value IS NOT NULL
       AND uq.value NOT IN ('', '""', 'null', '[null]', '[]')
       AND EXISTS (SELECT 1 FROM questions q WHERE q.id = uq.question_id AND q.deleted_at IS NULL)
    GROUP BY c.id
)
SELECT questions_answered, COUNT(*) AS candidates
FROM per_candidate
GROUP BY questions_answered
ORDER BY questions_answered;
