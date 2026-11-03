-- Matches & Engagement: what share of onboarded candidates have accepted a match?
-- Display: Number (percent, one decimal)
-- Active candidates who finished onboarding and have at least one accepted match, as a percent of all
-- active candidates who finished onboarding. Command's Accepted Matches tile, which uses the same
-- onboarding rule; it also counts deleted accounts and General Hospital's jobs.

WITH onboarded AS (
    SELECT id
    FROM users
    WHERE deleted_at IS NULL
      AND onboarding_step = 'Complete'
      AND recruiter = false
      AND adminsales IS NOT TRUE
      AND email NOT ILIKE '%@beginlyhealth.com'
      AND email NOT ILIKE '%@generalhospital.us'
),
accepted AS (
    SELECT DISTINCT om.user_id
    FROM opportunity_matches om
    JOIN onboarded c ON c.id = om.user_id
    WHERE om.deleted_at IS NULL
      AND om.candidate_reply_status = 'match_accepted'
      AND om.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
)
SELECT ROUND(100.0 * (SELECT COUNT(*) FROM accepted) / NULLIF((SELECT COUNT(*) FROM onboarded), 0), 1)
    AS accepted_match_pct;
