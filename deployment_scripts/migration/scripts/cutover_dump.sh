#!/usr/bin/env bash
# Consistent logical dump of memverse_production on fish-eagle (MySQL 5.7): everything except
# the data of the dead `sessions` table (921k rows, untouched since 2013; session store is cookies).
# --default-character-set=utf8mb4 is lossless for the latin1 and utf8 tables; --hex-blob protects
# binary columns. Prompts for the MySQL root password (mysql_config_editor, present on fish-eagle's 5.7.33).
# Plan §9 step 4 / Appendix A.1.
set -euo pipefail
DB=memverse_production
TS=$(date +%Y%m%d_%H%M%S)
OUT=/var/backups/memverse/cutover_$TS
mkdir -p "$OUT"
# The root password is entered once into mysql_config_editor (obfuscated ~/.mylogin.cnf, no quoting or
# escaping rules to get wrong, never in the environment or a plain file) and the login path is removed on exit.
LP=memverse-cutover
trap 'mysql_config_editor remove --login-path="$LP" >/dev/null 2>&1 || true' EXIT
echo "Enter the MySQL root password when prompted:"
mysql_config_editor set --login-path="$LP" --host=localhost --user=root --password
mysql --login-path="$LP" -e "SELECT 1" "$DB" >/dev/null
COMMON=(--login-path="$LP" --single-transaction --quick --hex-blob --no-tablespaces --default-character-set=utf8mb4)
echo "Dumping $DB (all tables except sessions data)..."
time mysqldump "${COMMON[@]}" --routines --triggers --events --ignore-table=$DB.sessions "$DB" | gzip -1 > "$OUT/full.sql.gz"
mysqldump "${COMMON[@]}" --no-data "$DB" sessions > "$OUT/sessions_schema.sql"
( cd "$OUT" && sha256sum full.sql.gz sessions_schema.sql > SHA256SUMS && ls -lh && cat SHA256SUMS )
echo "Dump at $OUT"
echo "Next: rsync -avP $OUT/ martial-eagle:/home/avitus/cutover/ && ssh martial-eagle 'cd cutover && sha256sum -c SHA256SUMS'"
