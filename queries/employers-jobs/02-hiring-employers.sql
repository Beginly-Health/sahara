-- Employers & Jobs: how many employers are hiring right now?
-- Display: Number
-- Active employers with at least one live job, without our own General Hospital (by ID). Read it beside
-- Active Employers: the gap is employers on Beginly with nothing live.

SELECT COUNT(DISTINCT e.id) AS hiring_employers
FROM employers e
JOIN opportunities o ON o.employer_id = e.id
WHERE e.deleted_at IS NULL
  AND e.id <> '01hbbc903rmz2pv9fgegy1qxp5'
  AND o.status = 'published'
  AND o.publish_date <= now()
  AND o.deleted_at IS NULL
  AND (o.close_date IS NULL OR o.close_date >= CURRENT_DATE);
