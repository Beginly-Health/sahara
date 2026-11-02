-- Beginly Overview: how many employers are on the platform?
-- Display: Number
-- Every employer that isn't deleted, without our own General Hospital (by ID: a client shares the name). Status has no meaning today.
-- Runs one lower than Command's Active Employers tile if General Hospital is in its count.

SELECT COUNT(*) AS active_employers
FROM employers
WHERE deleted_at IS NULL
  AND id <> '01hbbc903rmz2pv9fgegy1qxp5';
