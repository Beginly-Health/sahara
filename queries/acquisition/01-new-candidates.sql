-- Daily Acquisition: who signed up in the report window?
-- Display: Table
-- The "New Users" half of death-valley's daily #user-acquisition post (UserAcquisitionReportService),
-- one row per candidate, oldest first. Same window as the post: the 24 hours ending at the most recent
-- 08:30 Eastern. Set Report date to see an earlier day's window (it ends 08:30 Eastern on that date).
-- Variable: report_date (Date, optional). Wire it to the dashboard's date filter.
-- Candidates follow Sahara's rules, not the post's role check, so a rare account can differ.
-- Deleted accounts are left out, as in the post.

WITH report_window AS (
    SELECT
        (window_end_local - INTERVAL '1 day') AT TIME ZONE 'America/New_York' AS window_start,
        window_end_local AT TIME ZONE 'America/New_York' AS window_end
    FROM (
        SELECT COALESCE(
            [[{{report_date}}::date + TIME '08:30',]]
            date_trunc('day', (now() AT TIME ZONE 'America/New_York') - INTERVAL '8 hours 30 minutes')
                + INTERVAL '8 hours 30 minutes'
        ) AS window_end_local
    ) AS latest
)
SELECT
    u.created_at AS registered_at,
    u.name,
    COALESCE(NULLIF(replace(replace(u.source, '_', ' '), '-', ' '), ''), 'direct') AS source,
    (
        SELECT CASE
            WHEN uq.value LIKE '[%' THEN (
                SELECT string_agg(specialty, ', ')
                FROM jsonb_array_elements_text(uq.value::jsonb) AS specialty
                WHERE specialty <> ''
            )
            ELSE NULLIF(trim(BOTH '"' FROM uq.value), '')
        END
        FROM user_questions uq
        WHERE uq.user_id = u.id
          AND uq.question_id = '01gy38dysqnmd06nrh85wdzdnz'
          AND uq.deleted_at IS NULL
        LIMIT 1
    ) AS specialties,
    (
        SELECT upper(a.state)
        FROM addresses a
        WHERE a.addressable_type = 'App\Models\User'
          AND a.addressable_id = u.id
          AND a.deleted_at IS NULL
          AND a.state IS NOT NULL
          AND a.state <> ''
        ORDER BY a.primary DESC, a.created_at
        LIMIT 1
    ) AS home_state,
    (
        SELECT string_agg(DISTINCT upper(lp.state), ', ' ORDER BY upper(lp.state))
        FROM location_preferences lp
        WHERE lp.user_id = u.id
          AND lp.deleted_at IS NULL
          AND lp.rating > 5
    ) AS seeking_states,
    (
        SELECT COUNT(*)
        FROM user_questions uq
        JOIN questions q ON q.id = uq.question_id AND q.deleted_at IS NULL
        WHERE uq.user_id = u.id
          AND uq.deleted_at IS NULL
          AND uq.value IS NOT NULL
          AND uq.value NOT IN ('null', '[null]')
    ) AS questions_answered
FROM users u
CROSS JOIN report_window rw
WHERE u.recruiter = false
  AND u.adminsales IS NOT TRUE
  AND u.deleted_at IS NULL
  AND u.email NOT ILIKE '%@beginlyhealth.com'
  AND u.email NOT ILIKE '%@generalhospital.us'
  AND u.created_at BETWEEN rw.window_start AND rw.window_end
ORDER BY u.created_at;
