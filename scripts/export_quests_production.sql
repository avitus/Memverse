-- Direct SQL to export quest data for levels 1-18
-- Run on production MySQL:
-- mysql -u YOUR_USER -p YOUR_DATABASE -e "source export_quests_production.sql" > quest_inserts.sql

SELECT CONCAT(
  'INSERT INTO quests (level, objective, qualifier, quantity, task, description, url, created_at, updated_at) VALUES (',
  level, ', ',
  IFNULL(CONCAT("'", REPLACE(objective, "'", "''"), "'"), 'NULL'), ', ',
  IFNULL(CONCAT("'", REPLACE(qualifier, "'", "''"), "'"), 'NULL'), ', ',
  IFNULL(quantity, 'NULL'), ', ',
  IFNULL(CONCAT("'", REPLACE(task, "'", "''"), "'"), 'NULL'), ', ',
  IFNULL(CONCAT("'", REPLACE(description, "'", "''"), "'"), 'NULL'), ', ',
  IFNULL(CONCAT("'", REPLACE(url, "'", "''"), "'"), 'NULL'), ', ',
  'NOW(), NOW());'
) AS ''
FROM quests
WHERE level BETWEEN 1 AND 18
ORDER BY level, id;