#!/usr/bin/env bash
# Replace memverse_production on martial-eagle (MySQL 8.0) with the dump directory given as $1
# (must contain full.sql.gz, sessions_schema.sql and SHA256SUMS from cutover_dump.sh).
# Run as root (socket auth). The memverse@localhost grants survive the DROP/CREATE.
# Plan §9 step 6 / Appendix A.2.
set -euo pipefail
SRC=${1:?usage: cutover_restore.sh <dump dir>}
DB=memverse_production
( cd "$SRC" && sha256sum -c SHA256SUMS )
mysql -e "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci;"
mysql -e "SET GLOBAL innodb_flush_log_at_trx_commit = 2;"
trap 'mysql -e "SET GLOBAL innodb_flush_log_at_trx_commit = 1;"' EXIT
echo "Restoring into $DB..."
time ( printf 'SET SESSION sql_log_bin=0; SET SESSION foreign_key_checks=0; SET SESSION unique_checks=0;\n'
       zcat "$SRC/full.sql.gz"
       cat "$SRC/sessions_schema.sql" ) | mysql "$DB"
mysql -e "SELECT COUNT(*) AS tables_restored FROM information_schema.tables WHERE table_schema='$DB';"   # expect 83
