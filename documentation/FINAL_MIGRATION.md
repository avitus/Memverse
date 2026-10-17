# Final Migration: fish-eagle → martial-eagle

**Status as of 2026-10-17:** Phases 0–3 of the [migration runbook](plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md) are complete. martial-eagle is a fully built, tested production copy at the same revision as fish-eagle (`7dc9864b`). This file is the executable checklist for everything that remains. The runbook stays the reference for background and rationale; where the two differ, this file wins because it is newer.

**Window (decided 2026-10-17):** Sunday **2026-10-18, 02:00–03:30 PDT (09:00–10:30 UTC)**, brought forward from 8 November. Pacific is still PDT (UTC-7) until 1 November. Andy is available from about 02:20 PDT for the DNS change.

**Who does what:** Claude runs every server step as root over the `fish-eagle-root` and `martial-eagle-root` SSH aliases and as `avitus` over `memverse`/`martial-eagle` (while the `/etc/hosts` override is on the Mac, fish-eagle is reached as `ssh -o HostName=192.241.205.154 memverse`). Andy merges PRs, changes DNS at Linode, and gives the go/no-go.

**Gates.** The data steps run through [`deployment_scripts/migration/scripts/cutover.sh`](../deployment_scripts/migration/scripts/cutover.sh) from the repository root on the Mac. Each subcommand ends in `… OK` only when its check positively passed; anything else prints `CUTOVER STOP:` and exits non-zero. **Never continue past a step that did not print its `OK` line.** The rehearsal (1.2) runs the same subcommands, so the cutover path is exercised before the window.

**One writer at a time.** Before the DNS flip (2.7) only fish-eagle may serve users and only fish-eagle may run Sidekiq; martial-eagle's Sidekiq is fenced from 1.0 until 2.9. In any rollback the host being abandoned is fenced *before* the other is reopened, and the two proxies are never enabled together.

**Fixed facts**

| | fish-eagle (old) | martial-eagle (new) |
|---|---|---|
| IP | 192.241.205.154 | 64.23.176.115 |
| Enabled vhost | `/etc/nginx/sites-enabled/memverse.conf` | `/etc/nginx/sites-enabled/memverse` |
| Staged vhosts (`sites-available`) | `memverse-maintenance.conf`, `memverse-proxy.conf` | `memverse-maintenance`, `memverse-rollback-proxy` (both rollback only) |
| nginx reload | `nginx -t && nginx -s reload` (not under systemd) | `nginx -t && systemctl reload nginx` |
| Sidekiq units | `sidekiq-scheduler`, `sidekiq-workers@{1,2,3}` | `sidekiq-scheduler`, `sidekiq-workers@{1,2}` |
| Sidekiq fence | `systemctl disable` (2.2) | `cutover-fence.conf` drop-ins (`AssertPathExists` on a path that never exists, so `systemctl start` fails); unit files live in `/etc/systemd/system`, so `systemctl mask` is impossible |
| Database fence | No Memverse vhost + Sidekiq disabled. Root MySQL needs a password, and a global `read_only` would also freeze `andyvitus_production` on the same server, so there is no DB-level fence | `SET GLOBAL read_only` as root over the socket (rollback 4.2 only) |
| searchd | started by Capistrano (detached) | `memverse-searchd` systemd unit |
| Off-host backup | source of `memverse-backup.timer` until 2.10 | runs that timer (daily ~21:10 PDT, age + rclone); its own database from 2.10 |
| DNS | Linode, A records TTL 300 since 2026-10-11 | |
| TLS | Let's Encrypt, copied to martial-eagle, expires 2026-11-23 | reissue after the flip |

---

## 0. Decisions

- [x] **D7 `schedule_quiz` — decided 2026-10-17: remove it** (branch `claude/remove-schedule-quiz`). The every-minute `ScheduledQuiz` cron entry has been *disabled only in fish-eagle's Redis* since 2025-09-11; martial-eagle starts from a clean Redis, so it would run again. Redis-only disabling does not survive to a new host.
- [x] **D8 Cutover date** confirmed: Sunday 2026-10-18 02:00 PDT.

---

## 1. Before cutover (Saturday 2026-10-17; no production impact)

### 1.0 Fence martial-eagle's Sidekiq — Claude, 1 min, before any deploy
Capistrano starts Sidekiq after every deploy (`after :published`), so `cap production deploy` would start martial-eagle's workers against rehearsal data. Two layers stop that: `SKIP_SIDEKIQ_START=1` on every martial-eagle deploy until 2.9, and a systemd fence that makes any start fail loudly even if the variable is forgotten.
- [ ] ```bash
  ssh martial-eagle-root 'for d in sidekiq-scheduler.service.d sidekiq-workers@.service.d; do mkdir -p /etc/systemd/system/$d && printf "[Unit]\n# FINAL_MIGRATION.md 1.0: no Sidekiq on martial-eagle before the DNS flip. Removed in 2.9.\nAssertPathExists=/nonexistent/memverse-cutover-fence\n" > /etc/systemd/system/$d/cutover-fence.conf; done; systemctl daemon-reload; systemctl stop sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2; systemctl start sidekiq-scheduler 2>&1 | tail -1; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 | paste -sd" " -'
  ```
  Expect `Assertion failed on job for sidekiq-scheduler.service.` and `inactive inactive inactive`.

### 1.1 `schedule_quiz` deployed — Claude, 30 min, low risk
**Done 2026-10-17 10:56–11:02 PDT** at `32d21640` (PR #413 merged): fish-eagle release `20261017175606`, Sidekiq restarted, live schedule 8 jobs, no `schedule_quiz`; martial-eagle release published, its Sidekiq start refused by the 1.0 fence (the deploy reports that as a failure after publishing, which is expected), searchd active. No further deploy is needed before the cutover. If one is, use the commands below; the `SKIP_SIDEKIQ_START` guard ships with this PR, so the Mac's `main` checkout must contain it first.
- [x] PR `claude/remove-schedule-quiz` (#413) green and review-clean; Andy merged it.
- [x] Deploy fish-eagle (Sidekiq restarts there as usual):
  ```bash
  cd /Users/avitus/Projects/Memverse && git checkout main && git pull --ff-only && bundle exec cap fish_eagle deploy
  ```
- [x] Deploy martial-eagle **without** starting Sidekiq, then confirm it is still stopped:
  ```bash
  cd /Users/avitus/Projects/Memverse && SKIP_SIDEKIQ_START=1 bundle exec cap production deploy && ssh martial-eagle 'systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 | paste -sd" " -'
  ```
  Expect `SKIP_SIDEKIQ_START=1: Sidekiq left stopped` in the deploy output and `inactive inactive inactive`.
- [x] Destroy the stale Redis entry on fish-eagle if it is still listed (it was not on 2026-10-17: the schedule loader from PR #411 pruned it); expect no `schedule_quiz` line:
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'cd memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails runner "require %q(sidekiq/cron/job); Sidekiq::Cron::Job.find(%q(schedule_quiz))&.destroy; Sidekiq::Cron::Job.all.sort_by(&:name).each { |x| puts [x.name, x.status].join(%q(  )) }"'
  ```

### 1.2 Final rehearsal refresh — Claude, 10 min, no production impact
Exercises the exact cutover path. fish-eagle stays live, so `verify --report` will show differences in recently written tables; anything else (a missing table, martial-eagle ahead of fish-eagle, an error) is a defect to fix before tonight.
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh dump --rehearsal` → `DUMP OK: /var/backups/memverse/cutover_…` (`--rehearsal` skips the drain requirement; fish-eagle is live)
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh transfer` → `TRANSFER OK`
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh restore` → `RESTORE OK`
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh verify --report` → `VERIFY OK`
- [ ] `bash deployment_scripts/migration/scripts/smoke.sh 64.23.176.115` → `SMOKE OK`

### 1.3 Pre-flight, Saturday evening — Claude, 30 min, low risk, all reversible
- [ ] Deploy freeze from now until the window closes. Both hosts at the same revision:
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'cut -c1-8 memverse.com/current/REVISION'; ssh martial-eagle 'cut -c1-8 memverse.com/current/REVISION'
  ```
- [ ] martial-eagle: rehearsal Postmark test token **removed** (two `rehearsal.conf` drop-ins, one vhost line) while the fence drop-ins stay, Passenger restarted so no process still carries the token:
  ```bash
  ssh martial-eagle-root 'rm -f /etc/systemd/system/sidekiq-scheduler.service.d/rehearsal.conf /etc/systemd/system/sidekiq-workers@.service.d/rehearsal.conf; systemctl daemon-reload; sed -i "/passenger_env_var POSTMARK_API_TOKEN/d" /etc/nginx/sites-available/memverse; nginx -t && systemctl reload nginx; su - avitus -c "touch ~/memverse.com/current/tmp/restart.txt"; echo "token lines left: $(grep -c POSTMARK /etc/nginx/sites-available/memverse)"; ls /etc/systemd/system/sidekiq-*.d/; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 memverse-searchd mysql redis-server nginx | paste -sd" " -'
  ```
  Expect `token lines left: 0`, only `cutover-fence.conf` in both drop-in directories, and `inactive inactive inactive active active active active`.
- [ ] martial-eagle: stage the two rollback-only vhosts and the maintenance page, validate each in isolation (none is enabled):
  ```bash
  ssh martial-eagle-root 'install -D -m 0644 /dev/stdin /var/www/maintenance/index.html' < deployment_scripts/migration/fish-eagle/maintenance-index.html && scp deployment_scripts/migration/martial-eagle/memverse-maintenance.conf martial-eagle-root:/etc/nginx/sites-available/memverse-maintenance && scp deployment_scripts/migration/martial-eagle/memverse-rollback-proxy.conf martial-eagle-root:/etc/nginx/sites-available/memverse-rollback-proxy && ssh martial-eagle-root 'for f in memverse-maintenance memverse-rollback-proxy; do printf "events {}\nhttp { include /etc/nginx/mime.types; include /etc/nginx/sites-available/%s; }\n" "$f" > /tmp/nginx-check.conf; printf "%-26s " "$f"; nginx -t -c /tmp/nginx-check.conf 2>&1 | tail -1; done; rm -f /tmp/nginx-check.conf; ls /etc/nginx/sites-enabled/'
  ```
- [ ] fish-eagle: re-stage the proxy vhost (its `Connection` handling changed), check both staged vhosts in isolation, Sidekiq healthy:
  ```bash
  scp deployment_scripts/migration/fish-eagle/memverse-proxy.conf fish-eagle-root:/etc/nginx/sites-available/memverse-proxy.conf && ssh fish-eagle-root 'for f in memverse-maintenance.conf memverse-proxy.conf; do printf "events {}\nhttp { include /etc/nginx/mime.types; include /etc/nginx/sites-available/%s; }\n" "$f" > /tmp/nginx-check.conf; printf "%-26s " "$f"; nginx -t -c /tmp/nginx-check.conf 2>&1 | tail -1; done; rm -f /tmp/nginx-check.conf; test -s /var/www/maintenance/index.html && echo "maintenance page present"; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 | paste -sd" " -'
  ```
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh sites` → fish-eagle `memverse.conf`, martial-eagle `memverse`, `SITES OK`.
- [ ] martial-eagle: prepare the self-backup (read-only MySQL user, `~avitus/.my.backup.cnf`, backup key for `avitus@127.0.0.1`, known_hosts entry). It proves the path with a schema-only dump and does **not** change the current target:
  ```bash
  ssh martial-eagle-root 'bash -s' < deployment_scripts/migration/martial-eagle/prepare_self_backup.sh
  ```
  Expect `self-backup path OK, tables visible: 83` and `current target (unchanged): MEMVERSE_HOST=192.241.205.154`. The ~21:10 PDT run tonight is then the last off-host backup of fish-eagle.
- [ ] Live snapshot of fish-eagle (~5 min; safety net, delete a month after decommission):
  ```bash
  doctl compute droplet-action snapshot 18498427 --snapshot-name "fish-eagle-pre-cutover-$(date +%Y%m%d)" --wait --format ID,Status
  ```
- [ ] TTL still 300 at the authority:
  ```bash
  dig +noall +answer @ns1.linode.com www.memverse.com A memverse.com A
  ```
- [ ] fish-eagle must not be rebooted or updated before or during the window (uptime 8.5 years; it is the rollback asset). martial-eagle is not rebooted either.

---

## 2. Cutover window (~35–50 min)

**Rollback boundary.** Through 2.6 nothing but Andy's own signed-in check writes to martial-eagle, and martial-eagle runs no Sidekiq, so rollback 4.1 loses nothing except that check. From 2.7 on, users write to martial-eagle and rolling back is 4.2.

### 2.1 Maintenance on — fish-eagle, Claude, 1 min, reversible in seconds
- [ ] Note the start time. Start at 02:00 or later; the 09:00 UTC hourly reminder job is caught by the drain gate in 2.2 if it is still running.
  ```bash
  ssh fish-eagle-root 'rm /etc/nginx/sites-enabled/memverse.conf && ln -s /etc/nginx/sites-available/memverse-maintenance.conf /etc/nginx/sites-enabled/ && nginx -t && nginx -s reload && sleep 2 && curl -sS -o /dev/null -w "www -> %{http_code} (want 503)\n" --resolve www.memverse.com:443:127.0.0.1 https://www.memverse.com/'
  ```

### 2.2 Stop writes — fish-eagle, Claude, 2 min, reversible
- [ ] Quiet, stop and **disable** Sidekiq (disabled so it can never restart and double-run cron against the old database). `systemctl stop` gives running jobs Sidekiq's shutdown timeout and pushes unfinished ones back onto their queue, where the gate below sees them:
  ```bash
  ssh fish-eagle-root 'systemctl kill -s TSTP sidekiq-scheduler "sidekiq-workers@*"; sleep 30; systemctl stop sidekiq-scheduler "sidekiq-workers@*"; systemctl disable sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 2>&1 | grep -v Removed; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 | paste -sd" " -'
  ```
- [ ] Gate: `bash deployment_scripts/migration/scripts/cutover.sh drain` → `DRAIN OK`. It fails closed: the remote check must end with `DRAINED`, which it prints only if every probe ran, returned output in the expected format and showed zero; a probe error (`ps`, `passenger-status`, Redis) or the 90 s timeout is a failure, never a pass. nginx processes are selected by command name, so the check cannot match its own shell. It requires: only the maintenance vhost enabled, every Sidekiq unit inactive and disabled, no old nginx worker still finishing a request and no busy Passenger process (it waits up to 90 s), and in Redis no live Sidekiq process, no enqueued, no scheduled and no retrying job. Dead jobs are reported but not carried over. If it stops on jobs, it lists them: wait a minute and rerun, or **Andy decides** whether to drop them or have Claude re-enqueue them on martial-eagle after 2.4 (the restore flushes martial-eagle's Redis).

### 2.3 Final dump — fish-eagle, Claude, 1 min
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh dump` → `DUMP OK: /var/backups/memverse/cutover_…`. Refuses unless `drain` passed within the last 10 minutes; checks the dump's end marker and records the exact directory for 2.4.

### 2.4 Transfer and restore — Claude, ~4 min, destroys only rehearsal data
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh transfer` → `TRANSFER OK`. Copies the directory recorded in 2.3 (never "the newest one"), verifies SHA256SUMS on both ends and compares the two files.
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh restore` → `RESTORE OK`. Refuses unless that same directory was transferred and martial-eagle's Sidekiq is stopped; drops and recreates `memverse_production`, requires the restored table count to equal the dump's, **flushes Redis 0 and 1** (rehearsal queues, retries and cron records; the schedule reloads from the YAML in 2.9) and **clears the Rails file cache**.

### 2.5 Verify — Claude, 3 min. **Stop and ask Andy on any mismatch.**
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh verify` → `COUNTS IDENTICAL` then `VERIFY OK`. Per-table row counts, max ids and max `updated_at` from both hosts; each run must end with its `COUNTS COMPLETE` trailer, `sessions` is the only table excluded (data deliberately not dumped), any other difference stops the cutover. Then `db:migrate:status` on martial-eagle must list at least one migration up and none down.
- [ ] Sphinx reindexed against the restored data (~2 min); the searchd task fails the deploy unless searchd is active and listening:
  ```bash
  cd /Users/avitus/Projects/Memverse && bundle exec cap production thinking_sphinx:index memverse:searchd:restart
  ```

### 2.6 Smoke test — Claude, 3 min. **Go/no-go.**
- [ ] Restart Passenger and smoke test; Sidekiq stays fenced:
  ```bash
  ssh martial-eagle 'touch ~/memverse.com/current/tmp/restart.txt' && sleep 5 && bash deployment_scripts/migration/scripts/smoke.sh 64.23.176.115
  ```
  Expect `SMOKE OK`.
- [ ] Andy: signed-in spot check through the `/etc/hosts` override (sign in, review a verse). This is the only write before the flip; a no-go discards it. Jobs it enqueues wait in Redis until 2.9. **Go/no-go.** No-go → 4.1.

### 2.7 DNS flip — **Andy**, 2 min. Point of no free return. **Claude stops and asks before this step.**
- [ ] In the Linode DNS Manager change the A records for `memverse.com` and `www.memverse.com` to **64.23.176.115** (TTL stays 300).
- [ ] Claude verifies at the authority and public resolvers:
  ```bash
  for ns in ns1 ns2 ns3; do dig +noall +answer @$ns.linode.com www.memverse.com A memverse.com A | sed "s/^/$ns: /"; done; dig +short @1.1.1.1 www.memverse.com; dig +short @8.8.8.8 www.memverse.com
  ```

### 2.8 fish-eagle becomes a proxy — Claude, 1 min
- [ ] Switch maintenance → reverse proxy, so clients with cached DNS reach martial-eagle through fish-eagle (upstream certificate verified). The fish-eagle app stays unreachable and its Sidekiq disabled, which is its write fence:
  ```bash
  ssh fish-eagle-root 'rm /etc/nginx/sites-enabled/memverse-maintenance.conf && ln -s /etc/nginx/sites-available/memverse-proxy.conf /etc/nginx/sites-enabled/ && nginx -t && nginx -s reload && sleep 2 && curl -sS -o /dev/null -w "via fish-eagle -> %{http_code} (want 200)\n" --resolve www.memverse.com:443:127.0.0.1 https://www.memverse.com/users/sign_in'
  ```
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh sites` → fish-eagle `memverse-proxy.conf`, martial-eagle `memverse`, `SITES OK`.

### 2.9 Start Sidekiq on martial-eagle — Claude, 2 min
- [ ] Remove the fence, start the scheduler and both workers:
  ```bash
  ssh martial-eagle-root 'rm /etc/systemd/system/sidekiq-scheduler.service.d/cutover-fence.conf /etc/systemd/system/sidekiq-workers@.service.d/cutover-fence.conf && rmdir /etc/systemd/system/sidekiq-scheduler.service.d /etc/systemd/system/sidekiq-workers@.service.d && systemctl daemon-reload' && cd /Users/avitus/Projects/Memverse && bundle exec cap production sidekiq:multi:start && sleep 20 && ssh martial-eagle 'systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 | paste -sd" " -'
  ```
  Expect `active active active`. Start it before 03:00 PDT so the 10:00 UTC reminder run fires here.
- [ ] `bash deployment_scripts/migration/scripts/cutover.sh schedule` → `SCHEDULE OK: 8 jobs, all enabled, all UTC`. The loaded job names must equal the keys of `config/sidekiq_schedule.yml` in the Mac's checkout (same revision as deployed).

### 2.10 Backups follow production — Claude, 3 min
- [ ] Point the off-host backup at martial-eagle's own database and run it once now; the daily timer then keeps capturing production instead of the frozen old database:
  ```bash
  ssh martial-eagle-root 'sed -i "s/^MEMVERSE_HOST=.*/MEMVERSE_HOST=127.0.0.1/" /mnt/veetbot-secure/backup-config/memverse.env && grep ^MEMVERSE_HOST= /mnt/veetbot-secure/backup-config/memverse.env && systemctl start memverse-backup.service && journalctl -u memverse-backup.service --since "-10 min" --no-pager | grep -E "FATAL|verified remote size|done:"'
  ```
  Expect `MEMVERSE_HOST=127.0.0.1`, `verified remote size` and `done: memverse/daily/…`.
- [ ] Note the end time. Window closes.

---

## 3. Same day, after the window — Claude, ~1 h spread over the day

- [ ] **Reissue TLS on martial-eagle** once public resolvers return the new IP (~15 min after the flip); the copied certificate stays valid to 2026-11-23 as fallback:
  ```bash
  ssh martial-eagle-root 'certbot certonly --webroot -w /var/www/certbot -d memverse.com -d www.memverse.com --key-type ecdsa --non-interactive --agree-tos --keep-until-expiring --force-renewal 2>&1 | tail -3 && nginx -t && systemctl reload nginx && certbot renew --dry-run 2>&1 | tail -2'
  ```
- [ ] Watch for an hour: `shared/log/production.log`, `shared/log/nginx_error.log`, Sentry (host `martial-eagle`), New Relic, `free -h`.
- [ ] Confirm the next hourly `schedule_send_reminders` fired on the hour UTC (`shared/log/sidekiq.log`), then the next day's 08:00 and 12:00 UTC jobs, and the Tuesday 17:00 UTC quiz.
- [ ] Confirm Sunday's ~21:10 PDT timer run backed up martial-eagle (`journalctl -u memverse-backup.service`, MANIFEST `source=127.0.0.1`).
- [ ] After 48 h: **Andy** raises the two A-record TTLs to 3600 at Linode.
- [ ] Record the outcome and timings at the top of this file.

---

## 4. Rollback

Rule for every rollback: **fence the host being abandoned first, reopen the other one second, check `cutover.sh sites` third.** Only one database may accept writes at any moment, and fish-eagle's proxy (towards martial-eagle) and martial-eagle's rollback proxy (towards fish-eagle) must never be enabled together, or each forwards to the other.

### 4.1 Before the DNS flip (any step up to 2.7) — loses only Andy's test writes, 3 min
1. **Fence martial-eagle.** Sidekiq stopped (the 1.0 fence is still in place before 2.9), web traffic to maintenance:
   ```bash
   ssh martial-eagle-root 'systemctl stop sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2; test -f /etc/systemd/system/sidekiq-scheduler.service.d/cutover-fence.conf && test -f /etc/systemd/system/sidekiq-workers@.service.d/cutover-fence.conf && rm -f /etc/nginx/sites-enabled/memverse && ln -sf /etc/nginx/sites-available/memverse-maintenance /etc/nginx/sites-enabled/memverse-maintenance && nginx -t && systemctl reload nginx && systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 | paste -sd" " -'
   ```
2. **Reopen fish-eagle.** Remove maintenance *and* proxy (whichever is enabled), restore the production vhost, re-enable Sidekiq:
   ```bash
   ssh fish-eagle-root 'rm -f /etc/nginx/sites-enabled/memverse-maintenance.conf /etc/nginx/sites-enabled/memverse-proxy.conf && ln -sf /etc/nginx/sites-available/memverse.conf /etc/nginx/sites-enabled/memverse.conf && nginx -t && nginx -s reload && systemctl enable --now sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 && systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 | paste -sd" " -'
   ```
3. `bash deployment_scripts/migration/scripts/cutover.sh sites` → fish-eagle `memverse.conf`, martial-eagle `memverse-maintenance`, `SITES OK`. martial-eagle keeps the maintenance vhost until the next attempt starts again at 1.2.

### 4.2 After the flip, within hours — a decision, not a reflex
1. **Fence martial-eagle** (Claude): web to maintenance, Sidekiq stopped and fenced again, database read-only. From here nobody writes anywhere; fish-eagle's proxy now shows martial-eagle's maintenance page:
   ```bash
   ssh martial-eagle-root 'rm -f /etc/nginx/sites-enabled/memverse && ln -sf /etc/nginx/sites-available/memverse-maintenance /etc/nginx/sites-enabled/memverse-maintenance && nginx -t && systemctl reload nginx && systemctl stop sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 && for d in sidekiq-scheduler.service.d sidekiq-workers@.service.d; do mkdir -p /etc/systemd/system/$d && printf "[Unit]\nAssertPathExists=/nonexistent/memverse-cutover-fence\n" > /etc/systemd/system/$d/cutover-fence.conf; done && systemctl daemon-reload && mysql -e "SET GLOBAL read_only = 1; SET GLOBAL super_read_only = 1; SELECT @@read_only, @@super_read_only;"'
   ```
2. **Back up the writes made since the flip** (Claude): `ssh martial-eagle-root 'systemctl start memverse-backup.service'` (still targeting 127.0.0.1), confirm `done:`.
3. **Data decision** (Andy): either accept the loss of writes made on martial-eagle since the flip, or carry them back: dump martial-eagle with the **5.7 client on fish-eagle** over an SSH tunnel (an 8.0 `mysqldump` emits `utf8mb3`/`utf8mb4_0900_ai_ci` that 5.7 rejects) and load it into fish-eagle as the Memverse application's own MySQL user (credentials from `master.key`; root on fish-eagle needs a password).
4. **Reopen fish-eagle** (Claude): 4.1 step 2 (removes the proxy, restores `memverse.conf`, enables Sidekiq).
5. **Only after `cutover.sh sites` shows fish-eagle `memverse.conf`**, martial-eagle proxies to fish-eagle so clients that already resolve the new IP reach the one writable host:
   ```bash
   ssh martial-eagle-root 'rm -f /etc/nginx/sites-enabled/memverse-maintenance && ln -s /etc/nginx/sites-available/memverse-rollback-proxy /etc/nginx/sites-enabled/memverse-rollback-proxy && nginx -t && systemctl reload nginx' && bash deployment_scripts/migration/scripts/cutover.sh sites
   ```
6. **Andy** points the two A records back to 192.241.205.154.
7. Claude points the backup back at fish-eagle: `MEMVERSE_HOST=192.241.205.154` in `/mnt/veetbot-secure/backup-config/memverse.env`, then one run.

### 4.3 After a day
No rollback; fix forward on martial-eagle.

---

## 5. Following two weeks (low urgency)

- [ ] **Docs PR**: CLAUDE.md server section, `documentation/DEPLOYMENT.md`, remove Postmark test-token references, mark the runbook complete. Claude.
- [ ] **Backup restore proof.** Since 2.10 the daily backup dumps martial-eagle and stores it encrypted off-host (rclone remote). Andy decides whether that storage alone is enough or a second target is wanted; Claude **proves a restore** of one object into a scratch database. **Must precede decommission.**
- [ ] **andyvitus.com**: deploy to martial-eagle (Rails 7.2.2 / Ruby 3.2.6 / MySQL, same stack), certificate, Linode DNS flip; delete `realm.andyvitus.com`. Claude, ~1 h. Runbook §12.1.
- [ ] **Decommission fish-eagle** (≥ 14 days after cutover, Andy confirms): stop the proxy, final snapshot, destroy droplet 18498427; delete the pre-resize and pre-cutover snapshots a month later; remove the `fish_eagle` Capistrano stage, the `fish-eagle-root` alias, the 192.241.205.154 entry from the backup's known_hosts, and martial-eagle's two rollback-only vhosts.

---

## Risk summary

| Step | Exposure | Mitigation |
|---|---|---|
| 1.1 deploy to martial-eagle | Workers start against rehearsal data (cron, PubNub, rpush) | `SKIP_SIDEKIQ_START=1`, plus the 1.0 systemd fence that makes any start fail |
| 2.1–2.6 | Maintenance page only; Andy's test writes | martial-eagle has no Sidekiq until 2.9; 4.1 fences martial-eagle before reopening fish-eagle |
| In-flight requests and jobs at 2.1–2.2 | A write or job lands after the dump snapshot, or a queued job is lost | `cutover.sh drain` fails closed (probe errors and timeout fail): old nginx workers gone, Memverse Passenger idle with empty queues, Sidekiq stopped and disabled, no enqueued/scheduled/retry jobs; `dump` refuses without a drain pass in the last 10 min |
| Wrong or partial dump | Restore of an old or truncated dump | Dump end marker checked; exact directory recorded and carried; checksums on both ends; table count must equal the dump's |
| 2.5 checks | A failed check that looks like a pass | Count runs must end with a trailer; any non-`sessions` difference and any pending migration exits non-zero |
| 2.7 → 2.10 and after | Writes land on martial-eagle; rollback loses them | Go/no-go at 2.6; proxy keeps stragglers on the new data; 4.2 fences martial-eagle (web, Sidekiq, MySQL) before reopening fish-eagle |
| Proxy loop | Each host forwards to the other | Rollback order (fence, reopen, then proxy) and `cutover.sh sites` fails on the loop |
| Backups after the flip | Nightly backup keeps copying the frozen old database | 2.10 retargets the timer to martial-eagle and runs it once, inside the window |
| Cron state on a fresh Redis | Jobs disabled only in fish-eagle's Redis revive (`schedule_quiz`) | D7 removed it; Redis flushed at 2.4; `cutover.sh schedule` requires the loaded jobs to equal the YAML |
| Rehearsal email token | Real users emailed from the rehearsal | Removed at 1.3 and verified; Passenger restarted; Sidekiq fenced until 2.9 anyway |
| Stale cache after restore | Pages showing rehearsal-era data | Cache cleared at 2.4 |
| fish-eagle nginx | `systemctl reload` is a silent no-op there | All fish-eagle reloads use `nginx -s reload` |
| TLS after flip | Browser warnings | Copied cert valid to 2026-11-23; reissued same day |
| fish-eagle reboot | Rollback asset may not come back | Never reboot or update it until decommission |
