-- Metabase model: Opportunities. Start here for any opportunity or job question. "Job" and "opportunity" mean the same thing.
-- Display: Model (New > Model > Use a native query)
-- Every opportunity on Beginly, without our own General Hospital's (by ID: a client shares the name). Includes drafts, closed and deleted
-- ones. Use is_live for opportunities candidates can see today: published, past the publish date, not deleted, not closed.

SELECT
    o.id,
    o.title,
    o.employer_id,
    e.name AS employer_name,
    o.employer_branch_id,
    b.name AS branch_name,
    o.type,
    o.status,
    o.source,
    o.publish_date,
    o.close_date,
    o.created_at,
    o.salary_low,
    o.salary_high,
    o.status = 'published'
        AND o.publish_date <= now()
        AND o.deleted_at IS NULL
        AND (o.close_date IS NULL OR o.close_date >= CURRENT_DATE) AS is_live
FROM opportunities o
LEFT JOIN employers e ON e.id = o.employer_id
LEFT JOIN employer_branches b ON b.id = o.employer_branch_id
WHERE o.employer_id IS DISTINCT FROM '01hbbc903rmz2pv9fgegy1qxp5'
