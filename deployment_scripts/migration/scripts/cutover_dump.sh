#!/usr/bin/env bash
# Consistent logical dump of memverse_production on fish-eagle (MySQL 5.7): everything except
# the data of the dead `sessions` table (921k rows, untouched since 2013; session store is cookies).
# --default-character-set=utf8mb4 is lossless for the latin1 and utf8 tables; --hex-blob protects
# binary columns. Measured 2026-10-11 on fish-eagle: 16 s. Plan §9 step 4 / Appendix A.1.
set -euo pipefail
DB=memverse_production
TS=$(date +%Y%m%d_%H%M%S)
OUT=/var/backups/memverse/cutover_$TS
mkdir -p "$OUT"
# Credentials: prefer the read-only backup user's options file that the off-host backup already uses
# (no prompt, no root password). Fall back to mysql_config_editor (obfuscated ~/.mylogin.cnf, removed
# on exit, no quoting rules to get wrong) when that file is absent.
if [ -r "$HOME/.my.backup.cnf" ]; then
  echo "using $HOME/.my.backup.cnf (read-only backup user)"
  AUTH=(--defaults-extra-file="$HOME/.my.backup.cnf")
else
  LP=memverse-cutover
  trap 'mysql_config_editor remove --login-path="$LP" >/dev/null 2>&1 || true' EXIT
  echo "Enter the MySQL root password when prompted:"
  mysql_config_editor set --login-path="$LP" --host=localhost --user=root --password
  AUTH=(--login-path="$LP")
fi
mysql "${AUTH[@]}" -e "SELECT 1" "$DB" >/dev/null
COMMON=("${AUTH[@]}" --single-transaction --quick --hex-blob --no-tablespaces --default-character-set=utf8mb4)
echo "Dumping $DB (all tables except sessions data)..."
time mysqldump "${COMMON[@]}" --routines --triggers --events --ignore-table=$DB.sessions "$DB" | gzip -1 > "$OUT/full.sql.gz"
mysqldump "${COMMON[@]}" --no-data "$DB" sessions > "$OUT/sessions_schema.sql"
( cd "$OUT" && sha256sum full.sql.gz sessions_schema.sql > SHA256SUMS && ls -lh && cat SHA256SUMS )
echo "Dump at $OUT"
echo "Next: rsync -avP $OUT/ martial-eagle:/home/avitus/cutover/ && ssh martial-eagle 'cd cutover && sha256sum -c SHA256SUMS'"
