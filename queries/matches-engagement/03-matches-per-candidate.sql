-- Matches & Engagement: how many matches does a candidate get, on average?
-- Display: Number (one decimal)
-- Matches to active candidates divided by Total Active Candidates (overview/09), so candidates with no
-- matches pull it down. Command's Average Matches tile only counts candidates who finished the intro.

SELECT ROUND(
    (
        SELECT COUNT(*)
        FROM opportunity_matches om
        JOIN users u ON u.id = om.user_id
        WHERE om.deleted_at IS NULL
          AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
          AND u.deleted_at IS NULL
          AND u.recruiter = false
          AND u.adminsales IS NOT TRUE
          AND u.email NOT ILIKE '%@beginlyhealth.com'
          AND u.email NOT ILIKE '%@generalhospital.us'
    )::numeric
    / NULLIF((
        SELECT COUNT(*)
        FROM users
        WHERE deleted_at IS NULL
          AND recruiter = false
          AND adminsales IS NOT TRUE
          AND email NOT ILIKE '%@beginlyhealth.com'
          AND email NOT ILIKE '%@generalhospital.us'
    ), 0),
    1
) AS matches_per_candidate;
