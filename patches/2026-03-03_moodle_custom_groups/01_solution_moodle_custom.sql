INSERT INTO solution (name, active, source, target)
SELECT 'moodle_custom', active, source, target
FROM solution
WHERE name='moodle'
  AND NOT EXISTS (SELECT 1 FROM solution WHERE name='moodle_custom');
