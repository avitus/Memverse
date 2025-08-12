#!/usr/bin/env ruby
# SQL-based export script that can be run directly in MySQL
# This avoids Rails database connection issues

puts <<-SQL
-- Quest data export for levels 1-18
-- Run this SQL on your production database:
-- mysql -u YOUR_USER -p YOUR_DATABASE < export_quests.sql > quest_data.sql

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
) AS insert_statement
FROM quests
WHERE level BETWEEN 1 AND 18
ORDER BY level, id;
SQL