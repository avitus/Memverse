#!/usr/bin/env bash
# Consistent logical dump of memverse_production on fish-eagle (MySQL 5.7): everything except
# the data of the dead `sessions` table (921k rows, untouched since 2013; session store is cookies).
# --default-character-set=utf8mb4 is lossless for the latin1 and utf8 tables; --hex-blob protects
# binary columns. Prompts for the MySQL root password. Plan §9 step 4 / Appendix A.1.
set -euo pipefail
DB=memverse_production
TS=$(date +%Y%m%d_%H%M%S)
OUT=/var/backups/memverse/cutover_$TS
mkdir -p "$OUT"
# Password goes into a mode-600 options file that is removed on exit, never into the environment.
CNF=$(mktemp); chmod 600 "$CNF"
trap 'rm -f "$CNF"' EXIT
echo "MySQL root password:"; read -rs PW; printf '[client]\nuser=root\npassword=%s\n' "$PW" > "$CNF"; unset PW
mysql --defaults-extra-file="$CNF" -e "SELECT 1" "$DB" >/dev/null
COMMON=(--defaults-extra-file="$CNF" --single-transaction --quick --hex-blob --no-tablespaces --default-character-set=utf8mb4)
echo "Dumping $DB (all tables except sessions data)..."
time mysqldump "${COMMON[@]}" --routines --triggers --events --ignore-table=$DB.sessions "$DB" | gzip -1 > "$OUT/full.sql.gz"
mysqldump "${COMMON[@]}" --no-data "$DB" sessions > "$OUT/sessions_schema.sql"
( cd "$OUT" && sha256sum full.sql.gz sessions_schema.sql > SHA256SUMS && ls -lh && cat SHA256SUMS )
echo "Dump at $OUT"
echo "Next: rsync -avP $OUT/ martial-eagle:/home/avitus/cutover/ && ssh martial-eagle 'cd cutover && sha256sum -c SHA256SUMS'"
