#!/usr/bin/env bash
# Mac-side driver for the data steps of documentation/FINAL_MIGRATION.md (rehearsal 1.2, cutover 2.2-2.6).
# Every subcommand is a gate: it exits non-zero, with a line starting "CUTOVER STOP:", unless its check
# positively passed. A step that failed can therefore never look like a pass (empty output files, a
# swallowed ssh error, a count printed instead of enforced). The rehearsal runs exactly these subcommands.
#
#   cutover.sh drain             fish-eagle fenced: maintenance vhost only, Sidekiq stopped and disabled, no
#                                in-flight request, Redis has no queued, scheduled, retrying or live jobs.
#                                Fails closed: a probe that errors, cannot be parsed or times out fails
#   cutover.sh dump [--rehearsal] consistent dump on fish-eagle; records the exact dump directory it wrote.
#                                Refuses without a passing drain in the last 10 minutes, unless --rehearsal
#   cutover.sh transfer          copies that recorded directory to martial-eagle:~/cutover, checksums both ends
#   cutover.sh restore           martial-eagle: replace the database, flush Redis 0 and 1, clear the Rails cache
#   cutover.sh verify [--report] per-table counts diffed across hosts (sessions excepted), no pending migration;
#                                --report prints the differences and exits 0 (rehearsal: fish-eagle is still live)
#   cutover.sh schedule          martial-eagle Sidekiq-cron matches config/sidekiq_schedule.yml exactly
#   cutover.sh sites             which Memverse vhost each host serves; fails on a proxy loop or a double vhost
#
# Runs with macOS bash 3.2. State lives in $CUTOVER_STATE (default /tmp/memverse-cutover).
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
STATE=${CUTOVER_STATE:-/tmp/memverse-cutover}
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)
FISH=(ssh "${SSH_OPTS[@]}" -o HostName=192.241.205.154 memverse)
FISH_ROOT=(ssh "${SSH_OPTS[@]}" fish-eagle-root)
MARTIAL=(ssh "${SSH_OPTS[@]}" martial-eagle)
MARTIAL_ROOT=(ssh "${SSH_OPTS[@]}" martial-eagle-root)
RAILS='cd memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails'
DUMP_DIR_RE='^/var/backups/memverse/cutover_[0-9]{8}_[0-9]{6}$'

die() { echo "CUTOVER STOP: $*" >&2; exit 1; }
mkdir -p "$STATE"

recorded_dump() {
  [ -s "$STATE/dump_dir" ] || die "no dump recorded in $STATE/dump_dir; run: cutover.sh dump"
  local dir
  dir=$(cat "$STATE/dump_dir")
  [[ $dir =~ $DUMP_DIR_RE ]] || die "recorded dump directory '$dir' is not a cutover_dump.sh directory"
  echo "$dir"
}

cmd_drain() {
  # Fail closed: the remote check prints DRAINED as its last line only when every probe ran, produced
  # output in the expected format and showed zero; a failed probe, unparseable output or the timeout
  # all leave it out. No `set -e` in the remote script, so a probe's failure is handled, not fatal.
  local out
  rm -f "$STATE/drained" "$STATE/drain.out"
  "${FISH_ROOT[@]}" 'bash -s' > "$STATE/drain.out" 2>&1 <<'EOF' || true
set -uo pipefail
fail=0
bad() { echo "NOT DRAINED: $*"; fail=1; }
num() { [[ ${1:-} =~ ^[0-9]+$ ]]; }

enabled=$(ls /etc/nginx/sites-enabled/) || bad "cannot list sites-enabled"
echo "fish-eagle sites-enabled: $(echo $enabled)"
grep -qx 'memverse.conf' <<<"$enabled" && bad "memverse.conf is still enabled (maintenance not on)"
grep -qx 'memverse-maintenance.conf' <<<"$enabled" || bad "memverse-maintenance.conf is not enabled"
for u in sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3; do
  s=$(systemctl is-active "$u"); e=$(systemctl is-enabled "$u" 2>/dev/null)
  echo "$u: ${s:-?}, ${e:-?}"
  [ "$s" = inactive ] || [ "$s" = failed ] || bad "$u is ${s:-unknown}"
  [ "$e" = disabled ] || bad "$u is ${e:-unknown}, not disabled"
done

# One web probe. Sets old/busy/queued/web_err; returns 0 only when every number was read and is zero.
# nginx processes are selected by command name (ps -C), so no shell or pgrep can match itself, and the
# master must be present to prove the listing is real. passenger-status must exit 0 and show its
# general-information header; every application group whose path contains memverse.com counts.
web_probe() {
  old=; busy=; queued=; web_err=
  local procs pst groups
  if ! procs=$(ps -C nginx -o args=); then web_err="ps -C nginx failed"; return 1; fi
  grep -q '^nginx: master process' <<<"$procs" || { web_err="no nginx master process"; return 1; }
  old=$(grep -c 'worker process is shutting down' <<<"$procs")
  if ! pst=$(passenger-status 2>&1); then web_err="passenger-status failed: $(tail -1 <<<"$pst")"; return 1; fi
  grep -q '^----------- General information -----------$' <<<"$pst" || { web_err="passenger-status output not recognised"; return 1; }
  queued=$(awk -F': *' '/^Requests in top-level queue/ {print $2}' <<<"$pst")
  num "$queued" || { web_err="no top-level queue figure"; return 1; }
  groups=$(awk '/^\/.* \(.*\):$/ { g = ($0 ~ /memverse\.com/) } g' <<<"$pst")
  busy=$(awk '/\* PID:/ { for (i = 1; i < NF; i++) if ($i == "Sessions:" && $(i + 1) + 0 > 0) n++ } END { print n + 0 }' <<<"$groups")
  queued=$((queued + $(awk -F': *' '/Requests in queue/ { q += $2 } END { print q + 0 }' <<<"$groups")))
  num "$old" && num "$busy" || { web_err="could not count workers or sessions"; return 1; }
  [ "$old" -eq 0 ] && [ "$busy" -eq 0 ] && [ "$queued" -eq 0 ]
}
# Old nginx workers finish the requests they had accepted before the maintenance reload; wait up to 90 s
# for them and for every Memverse Passenger process to be idle. Timing out is a failure.
ok=0
for i in $(seq 1 45); do
  if web_probe; then ok=1; break; fi
  [ -n "$web_err" ] && break   # a probe that cannot run will not start working by waiting
  sleep 2
done
echo "old nginx workers=${old:-?} busy memverse passenger processes=${busy:-?} queued requests=${queued:-?}"
[ -n "$web_err" ] && bad "$web_err"
[ "$ok" -eq 1 ] || [ -n "$web_err" ] || bad "web requests still in flight after 90 s"

r() { redis-cli -n 0 "$@"; }
if [ "$(r PING)" != PONG ]; then
  bad "Redis does not answer PING"
else
  live=0
  for p in $(r SMEMBERS processes); do [ "$(r EXISTS "$p")" = 1 ] && live=$((live + 1)); done
  enq=0
  for q in $(r --scan --pattern 'queue:*'); do n=$(r LLEN "$q"); echo "$q=$n"; num "$n" || n=1; enq=$((enq + n)); done
  sched=$(r ZCARD schedule); retry=$(r ZCARD retry); dead=$(r ZCARD dead)
  echo "sidekiq live processes=$live enqueued=$enq scheduled=$sched retry=$retry dead=$dead (dead jobs are not carried over)"
  num "$sched" && num "$retry" || { bad "could not read the schedule or retry sets"; sched=1; retry=1; }
  [ "$live" -eq 0 ] || bad "$live Sidekiq processes still heartbeating"
  if [ "$enq" -gt 0 ] || [ "$sched" -gt 0 ] || [ "$retry" -gt 0 ]; then
    bad "jobs would be lost by the move; they are listed below. Wait and rerun, or decide explicitly to carry or drop them"
    for q in $(r --scan --pattern 'queue:*'); do r LRANGE "$q" 0 -1; done | cut -c1-200
    r ZRANGE schedule 0 -1 | cut -c1-200
    r ZRANGE retry 0 -1 | cut -c1-200
  fi
fi
[ "$fail" -eq 0 ] && echo DRAINED
EOF
  out=$(cat "$STATE/drain.out")
  echo "$out"
  [ "$(tail -1 <<<"$out")" = DRAINED ] || die "fish-eagle is not drained (above); do not dump"
  date +%s > "$STATE/drained"
  echo "DRAIN OK"
}

cmd_dump() {
  # The cutover dump is only taken right after a passing drain; the rehearsal says so explicitly.
  if [ "${1:-}" != --rehearsal ]; then
    [ -s "$STATE/drained" ] && [ $(( $(date +%s) - $(cat "$STATE/drained") )) -le 600 ] ||
      die "no passing 'cutover.sh drain' in the last 10 minutes (rehearsal: cutover.sh dump --rehearsal)"
  fi
  # pipefail makes an ssh or mysqldump failure fatal even though tee succeeds.
  "${FISH[@]}" 'bash -s' < "$HERE/cutover_dump.sh" | tee "$STATE/dump.log"
  local dir
  dir=$(sed -n 's/^DUMP_DIR=//p' "$STATE/dump.log" | tail -1)
  [[ $dir =~ $DUMP_DIR_RE ]] || die "cutover_dump.sh did not report DUMP_DIR"
  echo "$dir" > "$STATE/dump_dir"
  rm -f "$STATE/transferred_dir"
  echo "DUMP OK: $dir"
}

cmd_transfer() {
  local dir src dst
  dir=$(recorded_dump)
  "${FISH[@]}" "cd '$dir' && sha256sum -c --quiet SHA256SUMS >&2 && tar cf - full.sql.gz sessions_schema.sql SHA256SUMS" |
    "${MARTIAL[@]}" 'rm -rf ~/cutover && mkdir ~/cutover && tar xf - -C ~/cutover && cd ~/cutover && sha256sum -c SHA256SUMS'
  src=$("${FISH[@]}" "cat '$dir/SHA256SUMS'")
  dst=$("${MARTIAL[@]}" 'cat ~/cutover/SHA256SUMS')
  [ -n "$src" ] && [ "$src" = "$dst" ] || die "SHA256SUMS differ between fish-eagle:$dir and martial-eagle:~/cutover"
  echo "$dir" > "$STATE/transferred_dir"
  echo "TRANSFER OK: fish-eagle:$dir -> martial-eagle:/home/avitus/cutover"
}

cmd_restore() {
  local dir states
  dir=$(recorded_dump)
  [ -s "$STATE/transferred_dir" ] && [ "$(cat "$STATE/transferred_dir")" = "$dir" ] ||
    die "the recorded dump $dir has not been transferred; run: cutover.sh transfer"
  states=$("${MARTIAL_ROOT[@]}" 'systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 | paste -sd" " -' || true)
  [ "$states" = "inactive inactive inactive" ] || die "martial-eagle Sidekiq must be stopped before a restore (got: $states)"
  "${MARTIAL_ROOT[@]}" 'bash -s /home/avitus/cutover' < "$HERE/cutover_restore.sh"
  "${MARTIAL_ROOT[@]}" 'bash -s' <<'EOF'
set -euo pipefail
want=$(( $(zcat /home/avitus/cutover/full.sql.gz | grep -c '^CREATE TABLE') + 1 ))   # + sessions (schema only)
got=$(mysql -NBe "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'memverse_production'")
[ "$got" -eq "$want" ] || { echo "CUTOVER STOP: restored $got tables, dump has $want" >&2; exit 1; }
[ "$(redis-cli -n 0 FLUSHDB)" = OK ] && [ "$(redis-cli -n 1 FLUSHDB)" = OK ] || { echo "CUTOVER STOP: Redis flush failed" >&2; exit 1; }
find /home/avitus/memverse.com/shared/tmp/cache -mindepth 1 -delete
echo "tables=$got (dump: $want), Redis 0 and 1 flushed, Rails cache cleared"
EOF
  echo "RESTORE OK"
}

counts() { # fish|martial output-file. The Mac's copy of verify_counts.rb is streamed, so the check does
             # not depend on which release a host has deployed.
  local out=$2
  if [ "$1" = fish ]; then
    "${FISH[@]}" "$RAILS runner /dev/stdin" < "$HERE/verify_counts.rb" > "$out" 2> "$out.err" ||
      die "verify_counts.rb failed on fish-eagle (see $out.err)"
  else
    "${MARTIAL[@]}" "$RAILS runner /dev/stdin" < "$HERE/verify_counts.rb" > "$out" 2> "$out.err" ||
      die "verify_counts.rb failed on martial-eagle (see $out.err)"
  fi
  grep -q '^COUNTS COMPLETE' "$out" || die "$out lacks the COUNTS COMPLETE trailer (incomplete run)"
  grep -q $'^ROW\tusers\t[1-9]' "$out" || die "$out has no users rows"
}

cmd_verify() {
  local report=${1:-} up down
  counts fish "$STATE/counts_fish.tsv"
  counts martial "$STATE/counts_martial.tsv"
  for h in fish martial; do grep $'^ROW\t' "$STATE/counts_$h.tsv" | grep -v $'^ROW\tsessions\t' > "$STATE/counts_$h.cmp"; done
  grep $'^ROW\tsessions\t' "$STATE/counts_fish.tsv" "$STATE/counts_martial.tsv" | sed 's/^/excluded: /' || true
  if diff "$STATE/counts_fish.cmp" "$STATE/counts_martial.cmp"; then
    echo "COUNTS IDENTICAL ($(grep -c . "$STATE/counts_fish.cmp") lines, sessions excepted)"
  elif [ "$report" = --report ]; then
    echo "counts differ (above): expected in a rehearsal while fish-eagle still takes writes"
  else
    die "row counts differ between fish-eagle and martial-eagle (above)"
  fi
  "${MARTIAL[@]}" "$RAILS db:migrate:status" > "$STATE/migrate_status.txt" 2> "$STATE/migrate_status.err" ||
    die "db:migrate:status failed on martial-eagle (see $STATE/migrate_status.err)"
  up=$(grep -cE '^[[:space:]]*up[[:space:]]' "$STATE/migrate_status.txt" || true)
  down=$(grep -cE '^[[:space:]]*down[[:space:]]' "$STATE/migrate_status.txt" || true)
  echo "migrations up=$up down=$down"
  [ "$up" -gt 0 ] || die "db:migrate:status listed no applied migrations"
  [ "$down" -eq 0 ] || die "$down pending migrations on martial-eagle"
  echo "VERIFY OK"
}

cmd_schedule() {
  local want got
  want=$(ruby -ryaml -e 'puts YAML.load_file(ARGV[0]).keys.sort' "$REPO/config/sidekiq_schedule.yml")
  "${MARTIAL[@]}" "$RAILS runner 'require %q(sidekiq/cron/job); Sidekiq::Cron::Job.all.sort_by(&:name).each { |j| puts [%q(JOB), j.name, j.status, j.cron].join(%q(|)) }; puts %q(SCHEDULE COMPLETE)'" \
    > "$STATE/schedule.txt" 2> "$STATE/schedule.err" || die "Sidekiq::Cron listing failed (see $STATE/schedule.err)"
  grep -q '^SCHEDULE COMPLETE$' "$STATE/schedule.txt" || die "schedule listing incomplete"
  grep '^JOB|' "$STATE/schedule.txt" | cut -d'|' -f2- | sed 's/^/  /'
  got=$(grep '^JOB|' "$STATE/schedule.txt" | cut -d'|' -f2)
  [ "$got" = "$want" ] || die "loaded jobs differ from config/sidekiq_schedule.yml (want: $(echo $want))"
  ! grep '^JOB|' "$STATE/schedule.txt" | grep -vE '^JOB\|[^|]+\|enabled\|.* UTC$' | grep . ||
    die "a job above is not enabled or its cron lacks the UTC suffix"
  echo "SCHEDULE OK: $(echo "$want" | grep -c .) jobs, all enabled, all UTC"
}

cmd_sites() {
  local fish martial
  fish=$("${FISH_ROOT[@]}" 'ls /etc/nginx/sites-enabled/ | grep -E "^memverse" | paste -sd" " -')
  martial=$("${MARTIAL_ROOT[@]}" 'ls /etc/nginx/sites-enabled/ | grep -E "^memverse" | paste -sd" " -')
  echo "fish-eagle:    ${fish:-<none>}"
  echo "martial-eagle: ${martial:-<none>}"
  [ "$(echo "$fish" | wc -w)" -eq 1 ] || die "fish-eagle must have exactly one Memverse vhost enabled"
  [ "$(echo "$martial" | wc -w)" -eq 1 ] || die "martial-eagle must have exactly one Memverse vhost enabled"
  [ "$fish" = memverse-proxy.conf ] && [ "$martial" = memverse-rollback-proxy ] &&
    die "proxy loop: each host forwards to the other"
  echo "SITES OK"
}

case ${1:-} in
  drain) cmd_drain ;;
  dump) cmd_dump "${2:-}" ;;
  transfer) cmd_transfer ;;
  restore) cmd_restore ;;
  verify) cmd_verify "${2:-}" ;;
  schedule) cmd_schedule ;;
  sites) cmd_sites ;;
  *) sed -n '2,20p' "$0"; exit 2 ;;
esac
