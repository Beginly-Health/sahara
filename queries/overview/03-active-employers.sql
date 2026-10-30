-- Beginly Overview: how many employers are on the platform?
-- Display: Number
-- Matches Command's Active Employers tile, which counts every employer that isn't deleted.

SELECT COUNT(*) AS active_employers
FROM employers
WHERE deleted_at IS NULL;
