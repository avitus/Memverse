# Final Migration: fish-eagle → martial-eagle

**Status as of 2026-10-17:** Phases 0–3 of the [migration runbook](plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md) are complete. martial-eagle is a fully built, tested production copy at the same revision as fish-eagle (`7dc9864b`). This file is the executable checklist for everything that remains. The runbook stays the reference for background and rationale; where the two differ, this file wins because it is newer.

**Proposed window:** Sunday **2026-10-19, 02:00–03:30 PDT (09:00–10:30 UTC)**, brought forward from 8 November. Any quiet night works; avoid Tuesday 17:00 UTC and Saturday 23:00 UTC (quizzes). Pacific is still PDT (UTC-7) until 1 November.

**Who does what:** Claude runs every server step as root over the `fish-eagle-root` and `martial-eagle-root` SSH aliases and as `avitus` over `memverse`/`martial-eagle` (while the `/etc/hosts` override is on the Mac, fish-eagle is reached as `ssh -o HostName=192.241.205.154 memverse`). Andy merges PRs, changes DNS at Linode, and gives the go/no-go.

**Fixed facts**

| | fish-eagle (old) | martial-eagle (new) |
|---|---|---|
| IP | 192.241.205.154 | 64.23.176.115 |
| Enabled vhost | `/etc/nginx/sites-enabled/memverse.conf` | `/etc/nginx/sites-enabled/memverse` |
| nginx reload | `nginx -t && nginx -s reload` (not under systemd) | `nginx -t && systemctl reload nginx` |
| Sidekiq units | `sidekiq-scheduler`, `sidekiq-workers@{1,2,3}` | `sidekiq-scheduler`, `sidekiq-workers@{1,2}` |
| searchd | started by Capistrano (detached) | `memverse-searchd` systemd unit |
| DNS | Linode, A records TTL 300 since 2026-10-11 | |
| TLS | Let's Encrypt, copied to martial-eagle, expires 2026-11-23 | reissue after the flip |

---

## 0. Decisions still open

- [ ] **D7 `schedule_quiz`.** The every-minute `ScheduledQuiz` cron entry has been *disabled only in fish-eagle's Redis* since 2025-09-11. martial-eagle starts from a clean Redis, so after cutover it would run again. Options: **(a) remove it from `config/sidekiq_schedule.yml`** (recommended; same fix as the 2026-10-16 quiz incident, PR #411), or (b) decide it should run in production from now on. Redis-only disabling is not acceptable (it does not survive to a new host).
- [ ] **D8 Cutover date** confirmed.

---

## 1. Before cutover (any day; ~1 h of Claude's time, no production impact)

### 1.1 `schedule_quiz` PR (if D7 = remove) — Claude, 30 min, low risk
- [ ] Branch from `main`; delete the `schedule_quiz` block from `config/sidekiq_schedule.yml`; adjust `spec/config/sidekiq_schedule_spec.rb` expectations; run the suite; PR; review clean; **Andy merges**.
- [ ] Deploy to both hosts (Capistrano restarts Sidekiq on fish-eagle; on martial-eagle stop it again afterwards, it must not run before cutover):
  ```bash
  cd /Users/avitus/Projects/Memverse && git checkout main && git pull && bundle exec cap fish_eagle deploy
  ```
  ```bash
  cd /Users/avitus/Projects/Memverse && bundle exec cap production deploy && bundle exec cap production sidekiq:multi:stop
  ```
- [ ] Destroy the stale Redis entry on fish-eagle so the live schedule matches the YAML (Capistrano reload alone leaves the old job record):
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'cd memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails runner "require %q(sidekiq/cron/job); j = Sidekiq::Cron::Job.find(%q(schedule_quiz)); j&.destroy; Sidekiq::Cron::Job.all.each { |x| puts [x.name, x.status].join(%q(  )) }" 2>/dev/null | grep schedule_'
  ```

### 1.2 Final rehearsal refresh — Claude, 10 min, no production impact
- [ ] Dump on fish-eagle (read-only backup user, `--single-transaction`, ~16 s):
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'bash -s' < deployment_scripts/migration/scripts/cutover_dump.sh
  ```
- [ ] Transfer via the Mac and restore on martial-eagle (~3.5 min), then smoke test:
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'cd $(ls -dt ~/cutover_* | head -1) && tar cf - full.sql.gz sessions_schema.sql SHA256SUMS' | ssh martial-eagle 'rm -rf ~/cutover && mkdir ~/cutover && tar xf - -C ~/cutover' && ssh martial-eagle-root '/usr/local/sbin/memverse-cutover-restore.sh /home/avitus/cutover' && bash deployment_scripts/migration/scripts/smoke.sh 64.23.176.115
  ```

### 1.3 Pre-flight, the evening before — Claude, 20 min, low risk, all reversible
- [ ] Deploy freeze from now until the window closes. Both hosts at the same revision:
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'cut -c1-8 memverse.com/current/REVISION'; ssh martial-eagle 'cut -c1-8 memverse.com/current/REVISION'
  ```
- [ ] martial-eagle: Sidekiq stopped, searchd running, rehearsal Postmark test token **removed** (two drop-ins, one vhost line), Passenger restarted so no process still carries it:
  ```bash
  ssh martial-eagle-root 'systemctl stop sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2; rm -f /etc/systemd/system/sidekiq-scheduler.service.d/rehearsal.conf /etc/systemd/system/sidekiq-workers@.service.d/rehearsal.conf; rmdir /etc/systemd/system/sidekiq-scheduler.service.d /etc/systemd/system/sidekiq-workers@.service.d 2>/dev/null; systemctl daemon-reload; sed -i "/passenger_env_var POSTMARK_API_TOKEN/d" /etc/nginx/sites-available/memverse; nginx -t && systemctl reload nginx; su - avitus -c "touch ~/memverse.com/current/tmp/restart.txt"; echo "token lines left: $(grep -c POSTMARK /etc/nginx/sites-available/memverse)"; ls /etc/systemd/system/sidekiq-*.d 2>/dev/null; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 memverse-searchd mysql redis-server nginx | paste -sd" " -'
  ```
- [ ] fish-eagle: staged vhosts still valid (they are already in `/etc/nginx/sites-available/`), Sidekiq healthy:
  ```bash
  ssh fish-eagle-root 'for f in memverse-maintenance.conf memverse-proxy.conf; do printf "events {}\nhttp { include /etc/nginx/mime.types; include /etc/nginx/sites-available/%s; }\n" "$f" > /tmp/nginx-check.conf; printf "%-26s " "$f"; nginx -t -c /tmp/nginx-check.conf 2>&1 | tail -1; done; rm -f /tmp/nginx-check.conf; test -s /var/www/maintenance/index.html && echo "maintenance page present"; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 | paste -sd" " -'
  ```
- [ ] Live snapshot of fish-eagle (~5 min; safety net, delete a month after decommission):
  ```bash
  doctl compute droplet-action snapshot 18498427 --snapshot-name "fish-eagle-pre-cutover-$(date +%Y%m%d)" --wait --format ID,Status
  ```
- [ ] TTL still 300 at the authority:
  ```bash
  dig +noall +answer @ns1.linode.com www.memverse.com A memverse.com A
  ```
- [ ] fish-eagle must not be rebooted or updated before or during the window (uptime 8.5 years; it is the rollback asset).

---

## 2. Cutover window (~30–45 min)

Rollback is loss-free through step 2.6. From 2.7 on, rolling back means losing writes made on martial-eagle.

### 2.1 Maintenance on — fish-eagle, Claude, 1 min, reversible in seconds
- [ ] Note the start time.
  ```bash
  ssh fish-eagle-root 'rm /etc/nginx/sites-enabled/memverse.conf && ln -s /etc/nginx/sites-available/memverse-maintenance.conf /etc/nginx/sites-enabled/ && nginx -t && nginx -s reload && sleep 2 && curl -sS -o /dev/null -w "www -> %{http_code} (want 503)\n" --resolve www.memverse.com:443:127.0.0.1 https://www.memverse.com/'
  ```

### 2.2 Stop writes — fish-eagle, Claude, 2 min, reversible
- [ ] Quiet, stop and **disable** Sidekiq (disabled so it can never restart and double-run cron against the old database); confirm nothing in flight:
  ```bash
  ssh fish-eagle-root 'systemctl kill -s TSTP sidekiq-scheduler "sidekiq-workers@*"; sleep 30; systemctl stop sidekiq-scheduler "sidekiq-workers@*"; systemctl disable sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 2>&1 | grep -v Removed; systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 | paste -sd" " -; for q in critical high default low; do printf "queue:%s=%s " $q "$(redis-cli -n 0 LLEN queue:$q)"; done; echo; passenger-status 2>/dev/null | grep -E "Processed|Sessions" | head -4'
  ```

### 2.3 Final dump — fish-eagle, Claude, 1 min
- [ ] ```bash
  ssh -o HostName=192.241.205.154 memverse 'bash -s' < deployment_scripts/migration/scripts/cutover_dump.sh
  ```

### 2.4 Transfer and restore — Claude, ~4 min, destroys only rehearsal data
- [ ] Transfer, verify checksums, restore (drops and recreates `memverse_production`), **flush rehearsal Redis state** (queues, retries, cron records; the schedule reloads from the YAML), **clear the Rails file cache** (entries cached against the rehearsal data would otherwise survive):
  ```bash
  ssh -o HostName=192.241.205.154 memverse 'cd $(ls -dt ~/cutover_* | head -1) && tar cf - full.sql.gz sessions_schema.sql SHA256SUMS' | ssh martial-eagle 'rm -rf ~/cutover && mkdir ~/cutover && tar xf - -C ~/cutover' && ssh martial-eagle-root '/usr/local/sbin/memverse-cutover-restore.sh /home/avitus/cutover && redis-cli -n 0 FLUSHDB && redis-cli -n 1 FLUSHDB && rm -rf /home/avitus/memverse.com/shared/tmp/cache/* && echo "redis flushed, cache cleared"'
  ```

### 2.5 Verify — Claude, 3 min. **Stop here on any mismatch.**
- [ ] Per-table row counts, max ids and max `updated_at` on both hosts, diffed (only `sessions` may differ):
  ```bash
  for h in "-o HostName=192.241.205.154 memverse" "martial-eagle"; do ssh $h 'cd memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails runner deployment_scripts/migration/scripts/verify_counts.rb 2>/dev/null' > "/tmp/counts_$(echo $h | tr -c "a-z0-9" "_").txt"; done; diff /tmp/counts_*memverse*.txt /tmp/counts_martial*.txt && echo "COUNTS IDENTICAL"
  ```
- [ ] Migrations all up, Sphinx reindexed against the restored data (~2 min), searchd restarted:
  ```bash
  ssh martial-eagle 'cd memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails db:migrate:status 2>/dev/null | grep -c "^\s*down" | sed "s/^/pending migrations: /"' && cd /Users/avitus/Projects/Memverse && bundle exec cap production thinking_sphinx:index memverse:searchd:restart 2>&1 | grep -E "rotating|accepting|✘" 
  ```

### 2.6 Start the stack and smoke test — Claude, 3 min. **Go/no-go.**
- [ ] Start Sidekiq (expect 9 jobs loaded, all `UTC`; 8 if D7 removed `schedule_quiz`), restart Passenger, smoke test:
  ```bash
  cd /Users/avitus/Projects/Memverse && bundle exec cap production sidekiq:multi:start 2>&1 | grep -E "Starting|✘"; ssh martial-eagle 'touch ~/memverse.com/current/tmp/restart.txt; sleep 5; grep "Loaded .* scheduled jobs" ~/memverse.com/shared/log/production.log | tail -1; cd memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails runner "require %q(sidekiq/cron/job); Sidekiq::Cron::Job.all.sort_by(&:name).each { |j| puts [j.name, j.status, j.cron].join(%q(  |  )) }" 2>/dev/null | grep schedule_'; bash deployment_scripts/migration/scripts/smoke.sh 64.23.176.115
  ```
- [ ] Andy: signed-in spot check through the `/etc/hosts` override (sign in, review a verse). **Go/no-go.** No-go → section 4.1.

### 2.7 DNS flip — **Andy**, 2 min. Point of no free return.
- [ ] In the Linode DNS Manager change the A records for `memverse.com` and `www.memverse.com` to **64.23.176.115** (TTL stays 300).
- [ ] Claude verifies at the authority and public resolvers:
  ```bash
  for ns in ns1 ns2 ns3; do dig +noall +answer @$ns.linode.com www.memverse.com A memverse.com A | sed "s/^/$ns: /"; done; dig +short @1.1.1.1 www.memverse.com; dig +short @8.8.8.8 www.memverse.com
  ```

### 2.8 fish-eagle becomes a proxy — Claude, 2 min
- [ ] Switch maintenance → reverse proxy (clients with cached DNS are served by martial-eagle through fish-eagle; upstream certificate verified), set the old database read-only:
  ```bash
  ssh fish-eagle-root 'rm /etc/nginx/sites-enabled/memverse-maintenance.conf && ln -s /etc/nginx/sites-available/memverse-proxy.conf /etc/nginx/sites-enabled/ && nginx -t && nginx -s reload && sleep 2 && curl -sS -o /dev/null -w "via fish-eagle -> %{http_code} (want 200)\n" --resolve www.memverse.com:443:127.0.0.1 https://www.memverse.com/users/sign_in && mysql -e "SET GLOBAL read_only = 1; SET GLOBAL super_read_only = 1; SELECT @@read_only, @@super_read_only;"'
  ```
- [ ] Note the end time. Window closes.

---

## 3. Same day, after the window — Claude, ~1 h spread over the day

- [ ] **Reissue TLS on martial-eagle** once public resolvers return the new IP (~15 min after the flip); the copied certificate stays valid to 2026-11-23 as fallback:
  ```bash
  ssh martial-eagle-root 'certbot certonly --webroot -w /var/www/certbot -d memverse.com -d www.memverse.com --key-type ecdsa --non-interactive --agree-tos --keep-until-expiring --force-renewal 2>&1 | tail -3 && nginx -t && systemctl reload nginx && certbot renew --dry-run 2>&1 | tail -2'
  ```
- [ ] Watch for an hour: `shared/log/production.log`, `shared/log/nginx_error.log`, Sentry (host `martial-eagle`), New Relic, `free -h`.
- [ ] Confirm the next hourly `schedule_send_reminders` fired on the hour UTC (same runner command as 2.6), then the next day's 08:00 and 12:00 UTC jobs, and the Tuesday 17:00 UTC quiz.
- [ ] After 48 h: **Andy** raises the two A-record TTLs to 3600 at Linode.
- [ ] Record the outcome and timings at the top of this file.

---

## 4. Rollback

### 4.1 Before the DNS flip (any step up to 2.6) — loss-free, 2 min
```bash
ssh fish-eagle-root 'rm -f /etc/nginx/sites-enabled/memverse-maintenance.conf && ln -sf /etc/nginx/sites-available/memverse.conf /etc/nginx/sites-enabled/memverse.conf && nginx -t && nginx -s reload && systemctl enable --now sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 && systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3 | paste -sd" " -'
```
Then stop Sidekiq on martial-eagle (`cap production sidekiq:multi:stop`). Nothing was written anywhere else.

### 4.2 After the flip, within hours — a decision, not a reflex
1. Stop Sidekiq on martial-eagle; on fish-eagle `SET GLOBAL read_only = 0; SET GLOBAL super_read_only = 0;` and run 4.1.
2. Either accept the loss of writes made since the flip, or dump martial-eagle with the **5.7 client on fish-eagle** over an SSH tunnel (an 8.0 `mysqldump` emits `utf8mb3`/`utf8mb4_0900_ai_ci` that 5.7 rejects) and restore into fish-eagle.
3. Andy points DNS back to 192.241.205.154; Claude switches martial-eagle's vhost to proxy toward fish-eagle (mirror of A.6) for stale-DNS clients.

### 4.3 After a day
No rollback; fix forward on martial-eagle.

---

## 5. Following two weeks (low urgency)

- [ ] **Docs PR**: CLAUDE.md server section, `documentation/DEPLOYMENT.md`, remove Postmark test-token references, mark the runbook complete. Claude.
- [ ] **Off-host backups** to a new target (the current pull runs *from martial-eagle against fish-eagle*; it stops being off-host the moment fish-eagle goes). Andy chooses the target (DigitalOcean Spaces is the obvious one); Claude rebuilds the timer and **proves a restore**. **Must precede decommission.**
- [ ] **andyvitus.com**: deploy to martial-eagle (Rails 7.2.2 / Ruby 3.2.6 / MySQL, same stack), certificate, Linode DNS flip; delete `realm.andyvitus.com`. Claude, ~1 h. Runbook §12.1.
- [ ] **Decommission fish-eagle** (≥ 14 days after cutover, Andy confirms): stop the proxy, final snapshot, destroy droplet 18498427; delete the pre-resize and pre-cutover snapshots a month later; remove the `fish_eagle` Capistrano stage and the `fish-eagle-root` alias.

---

## Risk summary

| Step | Exposure | Mitigation |
|---|---|---|
| 2.1–2.6 | None beyond the maintenance page | Every step reversible in minutes (4.1) |
| 2.5 counts mismatch | Silent data loss | Hard stop; diff must be `sessions` only |
| 2.7 → 2.8 and after | Writes land on martial-eagle; rollback loses them | Go/no-go at 2.6 with smoke test and signed-in check; proxy keeps stragglers on the new data |
| Cron state on a fresh Redis | Jobs disabled only in fish-eagle's Redis revive (`schedule_quiz`) | D7 resolved before cutover; Redis flushed at 2.4 so the YAML is the only source |
| Rehearsal email token | Real users emailed from the rehearsal | Removed at 1.3 and verified; Passenger restarted |
| Stale cache after restore | Pages showing rehearsal-era data | Cache cleared at 2.4 |
| fish-eagle nginx | `systemctl reload` is a silent no-op there | All fish-eagle reloads use `nginx -s reload` |
| TLS after flip | Browser warnings | Copied cert valid to 2026-11-23; reissued same day |
| fish-eagle reboot | Rollback asset may not come back | Never reboot or update it until decommission |
| Off-host backups | None after fish-eagle is destroyed | Section 5 item 2 gates decommission |
