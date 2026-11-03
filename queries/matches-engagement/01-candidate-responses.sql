-- Matches & Engagement: how have candidates responded to their matches?
-- Display: Bar or Pie (x = response, y = matches)
-- Matches to active candidates that the candidate accepted, saved or declined, by where each stands now.
-- Matches with no response are left out; 02-engagement-rate shows what share of matches get one.
-- Command's Engagement tile on Sahara's rules: no staff or super admins, no General Hospital (by ID),
-- no deleted matches, and Saved needs saved_at, as in carcross. Command also requires a finished intro.

SELECT response, COUNT(*) AS matches
FROM (
    SELECT
        CASE
            WHEN om.candidate_reply_status = 'match_accepted' THEN 'Accepted'
            WHEN om.candidate_reply_status = 'saved' THEN 'Saved'
            ELSE 'Declined'
        END AS response
    FROM opportunity_matches om
    JOIN users u ON u.id = om.user_id
    WHERE om.deleted_at IS NULL
      AND (
          om.candidate_reply_status IN ('match_accepted', 'declined')
          OR (om.candidate_reply_status = 'saved' AND om.saved_at IS NOT NULL)
      )
      AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
      AND u.deleted_at IS NULL
      AND u.recruiter = false
      AND u.adminsales IS NOT TRUE
      AND u.email NOT ILIKE '%@beginlyhealth.com'
      AND u.email NOT ILIKE '%@generalhospital.us'
) AS responses
GROUP BY response
ORDER BY array_position(ARRAY['Accepted', 'Saved', 'Declined'], response);
