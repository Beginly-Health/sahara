-- Profile questions: which questions do candidates answer, and which do they skip?
-- Display: Table, or Row chart (y = question, x = pct_answered), in the order candidates see them
-- One row per question that isn't deleted, with how many active candidates have answered it and what share
-- of all active candidates that is. Ordered as death-valley lists them (relevance, then ordinal), so a
-- falling share shows where people stop. Some questions only show to certain specialties, so their share
-- of all candidates runs low by design. Command's Users Answered widget, on Sahara's candidate rules.
-- shown_in is the question's context in death-valley (profile, onboarding, ...).

WITH active_candidates AS (
    SELECT id
    FROM users
    WHERE deleted_at IS NULL
      AND recruiter = false
      AND adminsales IS NOT TRUE
      AND email NOT ILIKE '%@beginlyhealth.com'
      AND email NOT ILIKE '%@generalhospital.us'
),
answers AS (
    SELECT uq.question_id, COUNT(DISTINCT uq.user_id) AS candidates_answered
    FROM user_questions uq
    JOIN active_candidates c ON c.id = uq.user_id
    WHERE uq.deleted_at IS NULL
      AND uq.value IS NOT NULL
      AND uq.value NOT IN ('', '""', 'null', '[null]', '[]')
    GROUP BY uq.question_id
)
SELECT
    q.label AS question,
    (SELECT string_agg(ctx, ', ') FROM jsonb_array_elements_text(q.context) AS ctx) AS shown_in,
    COALESCE(a.candidates_answered, 0) AS candidates_answered,
    ROUND(100.0 * COALESCE(a.candidates_answered, 0) / NULLIF((SELECT COUNT(*) FROM active_candidates), 0), 1)
        AS pct_answered
FROM questions q
LEFT JOIN answers a ON a.question_id = q.id
WHERE q.deleted_at IS NULL
ORDER BY q.relevance DESC, q.ordinal;
