-- Matches & Engagement: how many matches does a candidate accept or save, on average?
-- Display: Number (one decimal)
-- Accepted plus saved matches divided by Total Active Candidates (overview/09). Command's Positive
-- Engagement tile, on Sahara's rules; Command only counts candidates who finished the intro.

SELECT ROUND(
    (
        SELECT COUNT(*)
        FROM opportunity_matches om
        JOIN users u ON u.id = om.user_id
        WHERE om.deleted_at IS NULL
          AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
          AND (
              om.candidate_reply_status = 'match_accepted'
              OR (om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL)
          )
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
) AS positive_responses_per_candidate;
