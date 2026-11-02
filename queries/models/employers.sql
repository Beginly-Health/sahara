-- Metabase model: Employers. Start here for any employer question.
-- Display: Model (New > Model > Use a native query)
-- Every employer on Beginly, without our own General Hospital (by ID: a client shares the name). Includes deleted
-- employers. Use is_active for active employers. Counts leave out deleted branches, recruiters and opportunities.
-- plan is assigned in Command and isn't fully implemented yet. status is left out: it has no meaning today.

SELECT
    e.id,
    e.name,
    'Tier ' || e.plan AS plan,
    e.created_at,
    e.deleted_at IS NULL AS is_active,
    (
        SELECT COUNT(*)
        FROM employer_branches b
        WHERE b.employer_id = e.id
          AND b.deleted_at IS NULL
    ) AS branch_count,
    (
        SELECT COUNT(*)
        FROM users u
        WHERE u.current_team_id = e.id
          AND u.deleted_at IS NULL
          AND u.adminsales IS NOT TRUE
          AND EXISTS (
              SELECT 1
              FROM model_has_roles mhr
              JOIN roles r ON r.id = mhr.role_id
              WHERE mhr.model_id = u.id
                AND mhr.model_type = 'App\Models\User'
                AND r.name = 'recruiter'
          )
    ) AS recruiter_count,
    (
        SELECT COUNT(*)
        FROM opportunities o
        WHERE o.employer_id = e.id
          AND o.deleted_at IS NULL
    ) AS total_opportunity_count,
    (
        SELECT COUNT(*)
        FROM opportunities o
        WHERE o.employer_id = e.id
          AND o.status = 'published'
          AND o.publish_date <= now()
          AND o.deleted_at IS NULL
          AND (o.close_date IS NULL OR o.close_date >= CURRENT_DATE)
    ) AS live_opportunity_count
FROM employers e
WHERE e.id <> '01hbbc903rmz2pv9fgegy1qxp5'
