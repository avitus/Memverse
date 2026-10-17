#!/usr/bin/env bash
# Prepare martial-eagle to back up its own Memverse database with the existing off-host pipeline
# (/usr/local/sbin/memverse-backup.sh: dump over ssh, age-encrypt, rclone upload). Today that job pulls
# from fish-eagle; after the DNS flip fish-eagle's database is frozen, so FINAL_MIGRATION.md 2.9 points
# MEMVERSE_HOST at 127.0.0.1. This script installs everything that switch needs and changes nothing
# the current backup uses. Idempotent. Run as root on martial-eagle (FINAL_MIGRATION.md 1.3):
#   ssh martial-eagle-root 'bash -s' < deployment_scripts/migration/martial-eagle/prepare_self_backup.sh
set -euo pipefail
CFG=/mnt/veetbot-secure/backup-config
KEY=$CFG/memverse_id_ed25519.pub
KNOWN=$CFG/memverse_known_hosts
CNF=/home/avitus/.my.backup.cnf
AUTH=/home/avitus/.ssh/authorized_keys

# 1. Read-only MySQL user; the password is generated here, kept only in the 0600 options file, never printed.
if [ -s "$CNF" ]; then
  PW=$(sed -n 's/^password=//p' "$CNF")
else
  PW=$(openssl rand -hex 24)
  install -o avitus -g avitus -m 0600 /dev/null "$CNF"
  printf '[mysqldump]\nuser=memverse_backup\npassword=%s\n' "$PW" > "$CNF"
fi
mysql <<SQL
CREATE USER IF NOT EXISTS 'memverse_backup'@'localhost' IDENTIFIED BY '$PW';
ALTER USER 'memverse_backup'@'localhost' IDENTIFIED BY '$PW';
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES ON memverse_production.* TO 'memverse_backup'@'localhost';
GRANT SHOW_ROUTINE ON *.* TO 'memverse_backup'@'localhost';
SQL
unset PW

# 2. The backup key may log in as avitus from this host only, with the same restrictions fish-eagle applies.
grep -qF "$(cut -d' ' -f2 "$KEY")" "$AUTH" ||
  printf 'from="127.0.0.1,::1",no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty %s\n' "$(cat "$KEY")" >> "$AUTH"

# 3. The job's strict known_hosts file must know this host as 127.0.0.1 (read from the host key itself).
ssh-keygen -F 127.0.0.1 -f "$KNOWN" >/dev/null ||
  printf '127.0.0.1 %s\n' "$(cut -d' ' -f1,2 /etc/ssh/ssh_host_ed25519_key.pub)" >> "$KNOWN"

# 4. Prove the path exactly as memverse-backup.sh will use it: key, known_hosts, options file, grants.
ssh -i "$CFG/memverse_id_ed25519" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="$KNOWN" avitus@127.0.0.1 \
    'mysqldump --defaults-extra-file=$HOME/.my.backup.cnf --single-transaction --no-tablespaces --routines --triggers --events --no-data --databases memverse_production | grep -c "CREATE TABLE"' |
  sed 's/^/self-backup path OK, tables visible: /'
grep '^MEMVERSE_HOST=' "$CFG/memverse.env" | sed 's/^/current target (unchanged): /'
