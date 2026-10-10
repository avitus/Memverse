# Memverse migration: fish-eagle → martial-eagle

**Date:** 2026-10-10
**Status:** Plan, decisions D1–D6 confirmed by Andy on 2026-10-10 (nothing has been changed on either droplet or in DNS)
**Goal:** Move the whole Memverse production stack from the fish-eagle droplet (Ubuntu 16.04, never rebooted in 8.5 years) to the martial-eagle droplet (Ubuntu 24.04) with one short, announced maintenance window.

**Approach in one paragraph.** Build martial-eagle as a complete second production host while fish-eagle keeps serving. Rehearse the full data move against a copy of the database until the restore-and-verify sequence is timed and boring. Then, in a single window of roughly 30–45 minutes: put fish-eagle into maintenance mode, stop its background workers, take a final consistent dump, restore it on martial-eagle, verify row counts, start the stack, smoke test, and flip DNS. After the flip, fish-eagle reverse-proxies to martial-eagle so clients with cached DNS keep working. fish-eagle is kept intact (database untouched, workers disabled) for two weeks as the rollback asset, then decommissioned.

Everything below was verified by reading both servers on 2026-10-10. Commands marked **[root]** must run as root on martial-eagle over SSH. Root SSH there is key-only today (`PasswordAuthentication no` is set globally even though `PermitRootLogin yes` is), and neither `deploy` nor the new `avitus` user has general sudo. §7.8 makes the key-only rule explicit with `PermitRootLogin prohibit-password` once the build is done. Everything else runs as `avitus` or from your Mac.

---

## 1. Current state (verified 2026-10-10)

### 1.1 The two droplets

| | fish-eagle (source) | martial-eagle (target) |
|---|---|---|
| Droplet ID | 18498427 | 598636029 |
| Region | **sfo1** | **sfo3** |
| Public IPv4 | 192.241.205.154 | 64.23.176.115 |
| Private IPv4 | 10.12.0.5 | 10.48.0.5, 10.124.0.2 |
| OS / kernel | Ubuntu 16.04.3, 4.4.0-116 | Ubuntu 24.04.4, 6.8.0-142 |
| vCPU / RAM / swap | 4 / 7.8 GB / none | 4 / 7.8 GB / 2 GB |
| Disk | 79 GB (25 GB used) | 154 GB (30 GB used) + 20 GB volume for veetbot |
| Uptime | 3117 days | 8 days |
| System time zone | **America/Los_Angeles** | **UTC** |
| Other tenants | andyvitus.com (Rails/Passenger), realm.andyvitus.com (Realm Object Server), assetcorrelation.com (dir only) | mankunkujazz.com (node/pm2, user `deploy`), veetbot.com (+api/browser/docs, user `veetbot`, Docker Postgres) |
| Memory in use | 4.1 GB (Memverse ≈ 3.8 GB of that) | 3.3 GB used, 4.6 GB available |

The droplets are in **different regions**, so there is no private networking between them. All transfer goes over the public internet via SSH. The daily off-host backup pull (martial-eagle → fish-eagle, restricted key `memverse-backup@martial-eagle`) already proves this path works.

### 1.2 Memverse stack on fish-eagle

| Component | fish-eagle today | martial-eagle target | Notes |
|---|---|---|---|
| App | release `20261008224714`, rev `f99be34b` (main) at `/home/avitus/memverse.com` | same path, same user | Capistrano 3.19.2, 5 releases kept |
| Ruby | 3.2.6 via RVM (`/home/avitus/.rvm`), linked to OpenSSL 1.0.2g | 3.2.6 via RVM, OpenSSL 3.0 | Ruby 3.2 supports OpenSSL 3 natively; `openssl` gem pin `~> 3.3.0` still fine |
| Node (asset precompile) | nvm v16.20.2 (hardcoded in deploy config) | nvm **v24.21.0** (Node 24 LTS, what dev runs) | only needed by `terser`/execjs during precompile |
| Web | custom-built nginx 1.12.2 + Passenger **6.0.27** gem module (`passenger_root` → RVM gem) | Ubuntu nginx 1.24 + Phusion `libnginx-mod-http-passenger` (noble repo verified) | no `passenger` gem in Gemfile; apt module replaces it |
| MySQL | **5.7.33**, 1.66 GB, 83 tables (81 InnoDB, 2 MyISAM), DB default charset `utf8`/`utf8_general_ci`, strict `sql_mode`, 128 MB buffer pool, no binlog | **8.0.46** (noble) | see §13 for the 5.7→8.0 analysis |
| Redis | 7.0.11 (custom unit, `redis-minimal.conf`), DB0 = Sidekiq, DB1 = ActionCable; last RDB save Aug 2025 | 7.0.15 (noble) | effectively non-persistent today; nothing to migrate |
| Memcached | running, 1 GB cap, **zero operations in 20 s** | **not installed** | `Rails.cache` is `ActiveSupport::Cache::FileStore` (`shared/tmp/cache`, 2.3 GB); memcached is a leftover |
| Sphinx | 2.2.9, `searchd` started by Capistrano (not systemd, would not survive a reboot), 27 MB indices | sphinxsearch 2.2.11 (noble) + a systemd unit | thinking-sphinx 5.6.0 supports both; indices are rebuilt on deploy |
| Sidekiq | 1 scheduler (concurrency 5) + 3 workers (concurrency 25) as systemd units; RSS 215 + 879 + 515 + 369 MB | same units | queues empty, 3 dead jobs, 10 cron jobs |
| TLS | Let's Encrypt (certbot 0.31, nginx authenticator), `memverse.com` + `www`, **expires 2026-11-23** (auto-renews from ~10-24) | certbot 2.9 (webroot `/var/www/certbot`, already used for the other sites) | copy the live cert first, reissue after DNS |
| DNS | Linode DNS (`ns1-5.linode.com`), A records for `memverse.com` and `www` → 192.241.205.154, **TTL 86400**; `origin.memverse.com` CNAME → www; mail/MX → Google | same records → 64.23.176.115 | TTL must be lowered ≥ 48 h ahead |
| Email | Postmark API (HTTPS) | unchanged | no local MTA on either box; not IP-bound |
| Monitoring | New Relic (key in `config/newrelic.yml`), Sentry (DSN in initializer) | unchanged | new host simply appears |
| Push / realtime | rpush (1 app, creds in DB), PubNub | unchanged | outbound only |
| Uploaded files | **none**: `shared/storage` empty, `ckeditor_assets` and `uploads` empty, 0 Active Storage blobs | nothing to copy | |
| Secrets | `shared/config/master.key` (linked), legacy `secrets.yml` + key (not linked, unused) | copy `master.key`; copy legacy files for completeness | DB password, Postmark token, `secret_key_base` all live in `credentials.yml.enc` |
| Traffic | ≈ 110 requests/min (incl. assets); 1,604 memverse rows updated in the last 24 h | | |

Sudoers on fish-eagle for `avitus` (needed by `lib/capistrano/tasks/sidekiq_multi.rake`): NOPASSWD `systemctl`, `journalctl`, `mv /tmp/sidekiq-*.service /etc/systemd/system/`.

### 1.3 Facts that shape the plan

1. **No files to migrate.** Only the database and `master.key` carry state. That makes a dump/restore cutover simple and fast.
2. **Redis carries nothing durable.** Sidekiq queues are empty; the cron schedule is loaded from `config/sidekiq_schedule.yml` at scheduler boot. We start with an empty Redis on martial-eagle.
3. **The `sessions` table is dead weight.** 921,796 rows, newest `updated_at` 2013-08-29, session store is `cookie_store`. We dump its schema but not its data, saving ~336 MB of the restore.
4. **Time zone is the subtle trap.** Rails `Time.zone` is UTC and `ActiveRecord.default_timezone` is `:utc` on both. But the app uses `Date.today` / `Time.now` in 74 places (spaced-repetition scheduling in `app/models/memverse.rb`, reminders), which follow the *process* TZ, Pacific on fish-eagle. Meanwhile sidekiq-cron fires in **UTC** today (et-orbi prefers `ENV['TZ']`, which is unset, then Rails `Time.zone` = UTC; confirmed by `last_enqueue` times, e.g. the Tuesday quiz at 17:00 UTC). The decided fix (D3) is to set **martial-eagle's system time zone to America/Los_Angeles**, which mirrors fish-eagle exactly: `Date.today` follows the Pacific system clock, `ENV['TZ']` stays unset, and sidekiq-cron keeps firing in UTC through Rails `Time.zone`. Pinning the cron strings to UTC (0.2) stays in as a guard. There are **no TIMESTAMP columns** in the schema, so MySQL's own time zone is irrelevant. The droplet-wide change also affects Mankunku and veetbot's native services, so §7.0 audits them first.
5. **MySQL 8 reserved words exist in the schema**: column `rank` on `american_states`, `churches`, `countries`, `groups`, `users`, and the table `groups`. ActiveRecord quotes identifiers, and no raw SQL string in `app/` or `lib/` uses them bare. Development already runs on MySQL 9.6 (Homebrew). CI still uses `mysql:5.7`; bumping it to 8.0 before the move turns this into a proven fact rather than an argument.
6. **Memory on martial-eagle is the real constraint.** Memverse as configured uses ≈ 3.8 GB; martial-eagle has ≈ 4.6 GB available with two other products on it. See decision D2.
7. **fish-eagle must not be rebooted.** It has run for 3117 days; `searchd` and possibly other things are not under systemd. It is the rollback asset, so leave it exactly as it is until decommissioning.

---

## 2. What moves, what does not

**Moves:** application code (fresh Capistrano deploy of the same revision), database (dump/restore), `master.key` (+ legacy `secrets.yml` files), nginx vhost (rewritten for nginx 1.24, TLS 1.2/1.3, HTTP/2, same bot-block rule), Sidekiq systemd units, Sphinx (fresh index), TLS certificate (copied, then reissued), DNS A records.

**Does not move:** Redis contents, memcached, the 2.3 GB file cache, logs (archive a copy if wanted), the `origin.memverse.com` CDN origin vhost (no `asset_host` is configured; drop it), andyvitus.com / realm.andyvitus.com / assetcorrelation.com (out of scope, but they block deleting fish-eagle, see §12).

---

## 3. Decisions to confirm before starting

| # | Decision | Recommendation | Why |
|---|---|---|---|
| D1 ✅ | Unix user on martial-eagle | **Create `avitus`**, same home layout | `/home/avitus/...` is hardcoded in `config/thinking_sphinx.yml`, `config/deploy.rb`, `config/deploy/production.rb`, both Sidekiq unit templates and the nginx vhost. A `memverse` service account is tidier but costs a config PR and a second set of things to get wrong. |
| D2 ✅ | Memory | **Resize martial-eagle to 16 GB (CPU/RAM-only resize, reversible)** before building, and still trim Memverse a little (2 workers instead of 3, Passenger pool capped at 4). | Memverse (≈ 3.8 GB) + the existing 3.3 GB leaves ~0.7 GB on an 8 GB box, and deploys (asset precompile, bundle install) spike well above that. Retiring fish-eagle offsets most of the cost. Fallback if you decline: §7.9 "8 GB variant". The resize powers the droplet off for 1–3 minutes, so it needs a slot acceptable to mankunku and veetbot. |
| D3 ✅ | Time zone | **Decided: set the whole droplet to America/Los_Angeles** (`timedatectl`), after auditing the other tenants (§7.0). Cron strings still get an explicit ` UTC` suffix as a guard (0.2). | Mirrors fish-eagle exactly with no env or code dependency: verse due dates roll over at midnight Pacific, quizzes stay at 17:00/23:00 UTC. The alternative (TZ only on Memverse processes) was offered and declined. |
| D4 ✅ | Maintenance window | **Sunday 02:00–03:30 PDT (09:00–10:30 UTC)**, after the 08:00 UTC forum notifier, before the 12:00 UTC metrics job, far from the Tuesday 17:00 UTC and Saturday 23:00 UTC quizzes. | Lowest traffic; two hourly reminder runs (09:00, 10:00 UTC) are skipped, which is acceptable. |
| D5 ✅ | MySQL | **8.0.46 from the Ubuntu 24.04 archive** (not 8.4, not managed DB). | Matches what CI will test; `mysql_native_password` still available for Sphinx's indexer if needed; one fewer moving part than a managed cluster. |
| D6 ✅ | Decommission | **Keep fish-eagle fully intact for 14 days** after cutover, then destroy. Decided: **realm.andyvitus.com is retired** (not migrated); **andyvitus.com moves to martial-eagle** as a small follow-on (§12.1) before fish-eagle is destroyed. | Rollback asset; the remaining site is a small Rails app on the same Ruby/Passenger stack. |

---

## 4. Timeline overview

| Phase | What | Downtime | Lead time |
|---|---|---|---|
| 0 | Repository changes (PR) and a no-op deploy to fish-eagle | none | week 1 |
| 1 | Lower DNS TTL to 300 s | none | ≥ 48 h before cutover |
| 2 | Build martial-eagle (resize, user, packages, services, nginx, cert copy) | 1–3 min for mankunku/veetbot during resize only | week 1–2 |
| 3 | Rehearsal: restore the off-host backup, deploy, smoke test, time the restore | none | week 2 |
| 4 | Cutover | **≈ 30–45 min** for Memverse | the chosen Sunday |
| 5 | Post-cutover: reissue cert, monitor two cron cycles, watch Sentry/New Relic | none | days 1–7 after |
| 6 | Decommission fish-eagle, fix off-host backups | none | ≥ 14 days after |

---

## 5. Phase 0 — Repository changes (one PR, deployable to fish-eagle as a no-op)

Everything here is safe to deploy to fish-eagle *before* the move; that is the point. Deploying the cron change to fish-eagle first proves it is a no-op there.

- [x] **0.1 CI on MySQL 8.0.** In `.circleci/config.yml` change `image: library/mysql:5.7` to `image: mysql:8.0` (keep `MYSQL_ROOT_PASSWORD`/`MYSQL_DATABASE`). Green CI = the schema's `rank`/`groups` identifiers and every query are proven on 8.0. Do not proceed to Phase 4 until this is green.
- [x] **0.2 Pin cron to UTC (guard).** Cron already fires in UTC and will keep doing so under D3, but make it explicit so a future `TZ` export can never shift the quizzes: in `config/sidekiq_schedule.yml` append ` UTC` to each `cron:` string (`"0 17 * * 2 UTC"`, `"*/1 * * * * UTC"`, …). Fugit accepts a trailing zone name. Add a spec that loads the file and asserts every expression parses with `Fugit.parse_cron` and carries a zone.
- [x] **0.3 Sidekiq unit templates** (`deployment_scripts/sidekiq-scheduler.service`, `deployment_scripts/sidekiq-workers@.service`): change `After=... redis.service mysql.service` to `After=network.target redis-server.service mysql.service` (noble's Redis unit is `redis-server.service`). Do **not** add a `TZ` environment line: with D3 the system clock is Pacific and an explicit `TZ` would be picked up by et-orbi ahead of Rails' UTC and shift cron. Harmless on fish-eagle (its unit files are not re-installed unless you run `cap production sidekiq:multi:setup`).
- [x] **0.4 Deploy target.** In `config/deploy/production.rb` change `server 'www.memverse.com'` to `server '64.23.176.115'` (never deploy by a name that is about to change). Add `config/deploy/fish_eagle.rb` as a copy of the current production stage pointing at `192.241.205.154`, so `cap fish_eagle deploy` remains possible during the overlap. Change the `SIDEKIQ_WORKERS` default from 3 to 2 (D2) in both `config/deploy/production.rb` and the four `ENV.fetch('SIDEKIQ_WORKERS', '3')` calls in `lib/capistrano/tasks/sidekiq_multi.rake`.
- [x] **0.5 Node path.** In both `config/deploy.rb` and `config/deploy/production.rb` replace `/home/avitus/.nvm/versions/node/v16.20.2/bin` with `/home/avitus/.nvm/versions/node/v24.21.0/bin` (Node 24 LTS, pinned; 7.5 installs exactly that version). The `fish_eagle` stage keeps v16.
- [x] **0.6 Add the server-side files to the repo** under `deployment_scripts/migration/` (`martial-eagle/`, `fish-eagle/`, `scripts/`, with a README mapping each file to its install path): the nginx vhost and Passenger limits (§7.7), `memverse-searchd.service` (§7.6), sudoers (§7.3), MySQL config (§7.4), logrotate, the fish-eagle maintenance and proxy vhosts (§9), and the scripts in Appendix A. The copies in this document are for reading; the files in the repo are what gets installed.
- [ ] **0.7 Run the full suite** (`bundle exec rspec`, `bundle exec cucumber features`, `npm run test:run`) and merge. Then `cap fish_eagle deploy` (or `cap production deploy` *before* 0.4 is merged) and confirm in `shared/log/sidekiq_scheduler.log` that all 10 jobs load and that the next hourly `schedule_send_reminders` `last_enqueue` is still on the hour UTC.

---

## 6. Phase 1 — DNS preparation (≥ 48 h before cutover)

- [ ] **1.1** In the Linode DNS Manager, set the TTL of the `memverse.com` A record and the `www.memverse.com` A record to **300 s** (5 min). Leave the values unchanged.
- [ ] **1.2** Verify at the authority (Linode publishes within ~15 min): `dig +noall +answer @ns1.linode.com www.memverse.com A` shows `300`.
- [ ] **1.3** Wait at least 24 h (resolvers cached the old 86400 s TTL), ideally 48 h, before Phase 4.

---

## 7. Phase 2 — Build martial-eagle

### 7.0 Set the droplet time zone to Pacific (D3) **[root]**
Do this first so every Memverse process, MySQL and log line is born under Pacific time, exactly like fish-eagle.
- [ ] **Audit the other tenants for local-time assumptions.** Pre-checked on 2026-10-10 (as `deploy`): `veetbot-backup.timer` (03:30), `mankunku-backup.timer` (03:50) and `memverse-backup.timer` (04:10) all carry an explicit `UTC` suffix, so they do not move; `certbot.timer` (00:00/12:00 local) will shift by 7–8 h, which is harmless; the `deploy` crontab is empty; `/etc/cron.d` has only certbot, e2scrub_all and sysstat; the `veetbot-*` unit files set no `TZ=`. Still to check as root before the change: `crontab -l` for root and `veetbot`, and whether any veetbot service or the Mankunku app formats or schedules anything in local time (they have been running under UTC since birth). Docker containers keep their own UTC.
- [ ] `sudo timedatectl set-timezone America/Los_Angeles` and confirm `timedatectl` / `date`.
- [ ] Long-running processes cache the zone: restart Mankunku (`pm2 restart mankunku` as deploy) and the native veetbot services at a quiet moment so they all agree. Expect log timestamps on the box to change from UTC to PDT/PST from this point.
- [ ] Note for later: MySQL installed in 7.4 will report `system_time_zone=PDT` like fish-eagle; harmless (no TIMESTAMP columns) and consistent.

### 7.1 Resize (D2) **[DO control panel]**
- [ ] Take a snapshot of martial-eagle. Resize → "CPU and RAM only" → 16 GB. Power-off is required; schedule it. Confirm `free -h` afterwards and that mankunku/veetbot came back (`pm2 ls`, `systemctl status veetbot-api`).

### 7.2 Create the `avitus` user **[root]**
```bash
sudo adduser --disabled-password --gecos "Memverse deploy" avitus
sudo mkdir -p /home/avitus/.ssh && sudo chmod 700 /home/avitus/.ssh
# paste the public half of ~/.ssh/id_ed25519 (the Capistrano key) into authorized_keys
sudo chown -R avitus:avitus /home/avitus/.ssh && sudo chmod 600 /home/avitus/.ssh/authorized_keys
```
Add to `~/.ssh/config` on your Mac:
```
Host martial-eagle
    HostName 64.23.176.115
    User avitus
    IdentityFile ~/.ssh/id_ed25519
```
Verify `ssh martial-eagle hostname` prints `martial-eagle`. Also `ssh -T git@github.com` from the box with agent forwarding (`ssh -A martial-eagle`) and `ssh-keyscan github.com >> ~/.ssh/known_hosts` as avitus, because Capistrano clones with `forward_agent: true`.

### 7.3 Sudoers for avitus **[root]**
Narrower than fish-eagle on purpose: each entry is the exact argument string that `lib/capistrano/tasks/sidekiq_multi.rake` sends (no sudoers wildcards, so no extra arguments, unit paths or pagers can be appended), worker instances 1 and 2 are enumerated (add lines for a third), and there is **no** rule that lets `avitus` place unit files under `/etc/systemd/system` (that would be a one-step path to root). The unit files are installed once by root in §7.6. Install the versioned file:
```bash
sudo install -m 0440 deployment_scripts/migration/martial-eagle/sudoers-avitus-memverse /etc/sudoers.d/avitus-memverse && sudo visudo -cf /etc/sudoers.d/avitus-memverse
```
Test as avitus: `sudo -n systemctl status sidekiq-scheduler --no-pager` must not ask for a password (it fails only because the unit is not installed yet); `sudo -n systemctl status sidekiq-scheduler` (no `--no-pager`), `sudo -n systemctl edit sidekiq-scheduler` and `sudo -n systemctl enable sidekiq-workers@1` must all be refused.

### 7.4 Packages **[root]**
```bash
sudo apt-get update
sudo apt-get install -y build-essential git curl gnupg2 dirmngr \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev libgdbm-dev libncurses-dev \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev default-libmysqlclient-dev shared-mime-info \
  mysql-server-8.0 redis-server sphinxsearch
```
Phusion Passenger module for Ubuntu's nginx (noble repo verified to exist):
```bash
sudo install -d /etc/apt/keyrings
curl -fsSL https://oss-binaries.phusionpassenger.com/auto-software-signing-gpg-key.txt | gpg --dearmor | sudo tee /etc/apt/keyrings/phusion.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/phusion.gpg] https://oss-binaries.phusionpassenger.com/apt/passenger noble main" | sudo tee /etc/apt/sources.list.d/passenger.list
sudo apt-get update && sudo apt-get install -y libnginx-mod-http-passenger
ls /etc/nginx/modules-enabled/   # expect 50-mod-http-passenger.conf
sudo passenger-config validate-install --auto
```
MySQL: create `/etc/mysql/mysql.conf.d/zz-memverse.cnf` (match fish-eagle's semantics, drop the 5.7-only options):
```ini
[mysqld]
bind-address            = 127.0.0.1
sql_mode                = ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
character_set_server    = utf8mb3
collation_server        = utf8mb3_general_ci
innodb_buffer_pool_size = 1G
innodb_redo_log_capacity = 256M
max_connections         = 200
max_allowed_packet      = 64M
binlog_expire_logs_seconds = 259200
```
(`NO_AUTO_CREATE_USER` and `query_cache_*` no longer exist in 8.0 and must not be set. On the 8 GB variant use `innodb_buffer_pool_size = 512M`.) Then:
```bash
sudo systemctl restart mysql && sudo systemctl enable mysql redis-server
sudo mysql -e "SELECT VERSION(), @@sql_mode, @@character_set_server;"
```
Create the database and user. Get the password from fish-eagle without echoing it into history: `ssh memverse 'cd memverse.com/current && ~/.rvm/bin/rvm 3.2.6 do bin/rails credentials:show' | grep -A4 '^database:'` (it also shows `username`/`host`; `host` must be absent or `localhost`).
```bash
sudo mysql
CREATE DATABASE memverse_production CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci;
CREATE USER 'memverse'@'localhost' IDENTIFIED BY '<password from credentials>';
GRANT ALL PRIVILEGES ON memverse_production.* TO 'memverse'@'localhost';
FLUSH PRIVILEGES;
```
Redis: defaults are fine (binds 127.0.0.1, RDB snapshots). Sphinx: leave `/etc/default/sphinxsearch` at `START=no` and `sudo systemctl disable --now sphinxsearch`; the package cron in `/etc/cron.d/sphinxsearch` is then inert. Do **not** install memcached.

### 7.5 Ruby and Node (as avitus)
```bash
gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm autolibs read-only          # deps were installed in 7.4; avoids RVM asking for sudo
rvm install 3.2.6 --disable-binary
rvm use 3.2.6 --default && ruby -ropenssl -e 'puts RUBY_VERSION, OpenSSL::OPENSSL_LIBRARY_VERSION'   # 3.2.6, OpenSSL 3.0.x
gem install bundler -v 2.4.22      # the BUNDLED WITH version in Gemfile.lock
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.nvm/nvm.sh && nvm install 24.21.0 && nvm alias default 24.21.0 && ls ~/.nvm/versions/node/   # must show v24.21.0, the path pinned in 0.5
```
`rvm current` must print `ruby-3.2.6` in a fresh non-interactive login (`ssh martial-eagle '~/.rvm/bin/rvm current'`); the Capistrano `check_rails_7` task depends on it.

### 7.6 Directory layout and systemd units
As avitus:
```bash
mkdir -p ~/memverse.com/shared/{config,log,tmp/pids,tmp/cache,tmp/sockets,public/assets,public/ckeditor_assets,public/uploads,storage,db/sphinx,binlog}
scp memverse:/home/avitus/memverse.com/shared/config/master.key ~/memverse.com/shared/config/ && chmod 600 ~/memverse.com/shared/config/master.key
scp 'memverse:/home/avitus/memverse.com/shared/config/secrets.yml*' ~/memverse.com/shared/config/   # legacy, unused, kept for completeness
```
Sidekiq units are installed by **root**, not by Capistrano (see §7.3): copy `deployment_scripts/sidekiq-scheduler.service` and `deployment_scripts/sidekiq-workers@.service` to the box, then `sudo install -m 0644 sidekiq-scheduler.service sidekiq-workers@.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2`. Repeat the install whenever the templates change; `cap fish_eagle sidekiq:multi:setup` and `cap fish_eagle sidekiq:multi:enable` exist for the old host only (the deploy user on martial-eagle cannot install, enable or disable units). Do **not** start the units until the rehearsal database is in place.

`searchd` under systemd so it survives reboots **[root]**, `/etc/systemd/system/memverse-searchd.service`:
```ini
[Unit]
Description=Sphinx searchd for Memverse
After=network.target mysql.service

[Service]
Type=simple
User=avitus
Group=avitus
ExecStart=/usr/bin/searchd --config /home/avitus/memverse.com/shared/production.sphinx.conf --nodetach
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```
`sudo systemctl enable memverse-searchd` only after the first deploy has generated `shared/production.sphinx.conf`. Capistrano's `thinking_sphinx:restart` still stops/starts `searchd` via its pid file on each deploy; `Restart=on-failure` means systemd does not fight it, and after a reboot the unit brings `searchd` back with the indices on disk.

### 7.7 nginx vhost **[root]**
Create `/etc/nginx/conf.d/passenger-memverse.conf`:
```nginx
passenger_max_pool_size 4;
passenger_pool_idle_time 300;
```
Create `/etc/nginx/sites-available/memverse` (port of fish-eagle's vhost with modern TLS; the CDN `origin.` block is dropped; the ACME location matches the box's existing certbot webroot convention):
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name www.memverse.com memverse.com;
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { return 301 https://www.memverse.com$request_uri; }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name memverse.com;
    ssl_certificate     /etc/letsencrypt/live/memverse.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/memverse.com/privkey.pem;
    return 301 https://www.memverse.com$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.memverse.com;

    ssl_certificate     /etc/letsencrypt/live/memverse.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/memverse.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL_memverse:10m;
    ssl_session_timeout 10m;

    root /home/avitus/memverse.com/current/public;
    access_log /home/avitus/memverse.com/shared/log/nginx_access.log;
    error_log  /home/avitus/memverse.com/shared/log/nginx_error.log error;

    passenger_enabled on;
    passenger_ruby /home/avitus/.rvm/wrappers/ruby-3.2.6/ruby;
    passenger_app_env production;
    passenger_min_instances 2;

    if ($http_user_agent ~* (GPTBot|ClaudeBot|Google-Extended|CCBot|FacebookBot|Amazonbot|PerplexityBot|DuckDuckBot|Applebot|YouBot|Baiduspider|AhrefsBot|Bytespider)) {
        return 403;
    }

    location ~ ^/(assets)/ {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
        add_header Last-Modified "";
        add_header ETag "";
        break;
    }

    error_page 500 502 503 504 /500.html;
    location = /500.html { root /home/avitus/memverse.com/current/public; }
}
```
Before enabling it, bring over the live certificate so the vhost is valid pre-cutover (the cert is good until 2026-11-23 and will be reissued in §10):
```bash
# on fish-eagle (sudo), then copy to martial-eagle (sudo) preserving the live/ + archive/ + renewal/ layout
sudo tar -C /etc/letsencrypt -czf /tmp/le-memverse.tgz live/memverse.com archive/memverse.com renewal/memverse.com.conf
# martial-eagle:
sudo tar -C /etc/letsencrypt -xzf le-memverse.tgz && sudo chmod 600 /etc/letsencrypt/archive/memverse.com/privkey*.pem
sudo ln -s /etc/nginx/sites-available/memverse /etc/nginx/sites-enabled/memverse
sudo nginx -t && sudo systemctl reload nginx
```
(`nginx -t` needs the certificate files in place; the app root may not exist until the first deploy in §8, which is fine. From ~2026-10-24 the certbot timer on martial-eagle will try to renew this copied lineage with the `nginx` authenticator and fail, and fish-eagle will renew its own copy; both are harmless until the reissue in §10.)

Log rotation: add `/etc/logrotate.d/memverse` for `/home/avitus/memverse.com/shared/log/*.log` (daily, 14 rotations, `compress`, `delaycompress`, `copytruncate`), which fish-eagle does informally today.

### 7.8 Firewall and reboot safety **[root]**
- Confirm the DO cloud firewall (if any) on martial-eagle allows 22/80/443 (it already serves the other sites). MySQL, Redis, Sphinx bind to 127.0.0.1 only.
- `grep -E 'Automatic-Reboot' /etc/apt/apt.conf.d/50unattended-upgrades`: if automatic reboots are on, every Memverse unit must be `enabled` (they will be) so an unattended reboot is survivable.
- When the build is complete, make root SSH explicitly key-only: `/etc/ssh/sshd_config.d/10-root.conf` with `PermitRootLogin prohibit-password`, then `sudo sshd -t && sudo systemctl reload ssh`. (Password auth is already off globally; this removes the ambiguity.)

### 7.9 "8 GB variant" (only if D2 is declined)
`SIDEKIQ_WORKERS=1`, `concurrency: 10` in `config/sidekiq_workers.yml`, `passenger_max_pool_size 3`, `innodb_buffer_pool_size = 512M`. Expect ≈ 2.3 GB for Memverse and little headroom during deploys.

---

## 8. Phase 3 — Rehearsal (no downtime, repeat until boring)

The order matters: the database must exist with data **before** the first `cap production deploy`, otherwise `deploy:migrations`/`thinking_sphinx:index` would run against an empty schema.

- [ ] **3.1 Get a database copy.** Either the daily off-host backup already landing on martial-eagle (locate it with `sudo systemctl cat memverse-backup.service` and `sudo cat /usr/local/sbin/memverse-backup.sh`; the destination is root-only), or run Appendix A.1 on fish-eagle outside the window (it is `--single-transaction`, so it is safe while live).
- [ ] **3.2 Restore** with Appendix A.2 and **time it**. Record wall-clock for dump, transfer and restore; this sizes the window. (Estimate: dump 2–4 min, transfer < 1 min for ~250 MB, restore 5–12 min.)
- [ ] **3.3 Verify** with Appendix A.3: run it on both hosts and `diff` the outputs; the only expected differences are `sessions` (0 rows) and any rows written on fish-eagle since the dump.
- [ ] **3.4 First deploy** from the Mac on the Phase 0 branch/merge: `cap production deploy:check` then `cap production deploy`. Watch for: `bundle install` native builds (mysql2, nokogiri with system libs, ffi, sassc, rinku), asset precompile under Node 24.21.0, `db:migrate` reporting nothing to do, `thinking_sphinx:index` and `:restart` succeeding, `Rails.cache.clear` hook. Then enable the nginx vhost (§7.7) and `sudo systemctl enable memverse-searchd`.
- [ ] **3.5 Sphinx indexer vs MySQL 8 auth.** If `ts:index` fails to connect, the packaged `indexer` cannot do `caching_sha2_password`; fix with `ALTER USER 'memverse'@'localhost' IDENTIFIED WITH mysql_native_password BY '<same password>'` and note it in this doc.
- [ ] **3.6 Sandbox outbound email, then start Sidekiq.** The rehearsal scheduler enqueues real cron jobs against the restored data (hourly reminder emails to real users), and a job can fire the moment the scheduler starts, so stopping it afterward is not a safeguard. **Before** `sidekiq:multi:start`, point the whole rehearsal stack at a Postmark sandbox server token **[root]**: create `/etc/systemd/system/sidekiq-scheduler.service.d/rehearsal.conf` and `/etc/systemd/system/sidekiq-workers@.service.d/rehearsal.conf`, each containing `[Service]` / `Environment="POSTMARK_API_TOKEN=<sandbox token>"`, and add `passenger_env_var POSTMARK_API_TOKEN <sandbox token>;` to the vhost. The token is a secret, so lock the three files down before reloading anything: `sudo chown root:root /etc/systemd/system/sidekiq-scheduler.service.d/rehearsal.conf /etc/systemd/system/sidekiq-workers@.service.d/rehearsal.conf /etc/nginx/sites-available/memverse && sudo chmod 600 /etc/systemd/system/sidekiq-scheduler.service.d/rehearsal.conf /etc/systemd/system/sidekiq-workers@.service.d/rehearsal.conf /etc/nginx/sites-available/memverse` (systemd and the nginx master both read as root). Then `sudo systemctl daemon-reload` and `sudo nginx -t && sudo systemctl reload nginx` (`config/environments/production.rb` prefers the env var over credentials). Then `cap production sidekiq:multi:start` (units were enabled by root in 7.6), check `shared/log/sidekiq_scheduler.log` for `Loaded 10 scheduled jobs`, and confirm the rehearsal's first messages land in the Postmark sandbox, not a real inbox. Stop Sidekiq before Phase 4 (pre-flight).
- [ ] **3.7 Smoke test without touching DNS.** On the Mac add `64.23.176.115 www.memverse.com memverse.com` to `/etc/hosts` (remove afterwards!) or use `curl --resolve`. Run Appendix A.4. Then in a browser: sign in with your own account (the cookie is signed by the same `secret_key_base`, so existing sessions carry over), review a verse, open the forum and blog, open `/admin`, run a verse search (`/verses/verse_search`, the only Thinking Sphinx check that a signed-out smoke test cannot do), request a password reset (lands in the Postmark sandbox, which also proves outbound HTTPS from the new IP), and trigger `Sentry.capture_message("martial-eagle rehearsal")` via `rails runner` to see the new host in Sentry. Check New Relic shows a second host.
- [ ] **3.8 Reboot test (optional but valuable).** If an agreed slot exists for mankunku/veetbot, `sudo reboot` martial-eagle and confirm mysql, redis-server, nginx, memverse-searchd and the Sidekiq units all come back `active`.
- [ ] **3.9 Repeat 3.1–3.3 once more** right before the cutover week so the procedure and its timings are fresh, and so the rehearsal DB is close to production (makes the final restore's "diff" small).
- [ ] **3.10 Confirm fish-eagle can verify martial-eagle's certificate** (the post-cutover proxy in A.6 uses `proxy_ssl_verify on`): on fish-eagle run `openssl s_client -connect 64.23.176.115:443 -servername www.memverse.com -CAfile /etc/ssl/certs/ca-certificates.crt </dev/null 2>/dev/null | grep 'Verify return code'` and expect `0 (ok)`. If Ubuntu 16.04's bundle is too old for the Let's Encrypt roots, build `/etc/nginx/le-roots.pem` from https://letsencrypt.org/certs/isrgrootx1.pem and isrg-root-x2.pem, re-run the check with `-CAfile /etc/nginx/le-roots.pem`, and point `proxy_ssl_trusted_certificate` at it.

---

## 9. Phase 4 — Cutover runbook

### Pre-flight (T-24 h)
- [ ] `dig +noall +answer @ns1.linode.com www.memverse.com A` and `memverse.com A` both show TTL **300**.
- [ ] CI green on MySQL 8.0 (0.1); Phase 0 merged and deployed; `cap production deploy` to martial-eagle is at the **same revision** fish-eagle runs (`cat /home/avitus/memverse.com/current/REVISION` on both).
- [ ] Deploy freeze announced to yourself and alexcwatt (the other user on fish-eagle).
- [ ] martial-eagle Sidekiq units **stopped** (`cap production sidekiq:multi:stop`) and `searchd` stopped (`sudo systemctl stop memverse-searchd`; `pgrep searchd` empty).
- [ ] Rehearsal email sandbox **removed** **[root]**: delete both `rehearsal.conf` drop-ins (`ls /etc/systemd/system/sidekiq-*.d/` shows nothing), `sudo systemctl daemon-reload`, remove the `passenger_env_var POSTMARK_API_TOKEN` line from the vhost and restore its normal mode (`sudo chmod 644 /etc/nginx/sites-available/memverse`), `sudo nginx -t && sudo systemctl reload nginx`. Production email must use the real token from credentials from step 10 onward.
- [ ] Live DO snapshot of fish-eagle (safety net; takes a while, do it the night before).
- [ ] Maintenance page in place on fish-eagle but **not enabled**: `/var/www/maintenance/index.html` (from `deployment_scripts/migration/fish-eagle/`) and `/etc/nginx/sites-available/memverse-maintenance.conf` (A.5); post-cutover proxy staged as `/etc/nginx/sites-available/memverse-proxy.conf` (A.6). `nginx -t` only parses enabled files, so validate each staged file in isolation: `printf 'events {}\nhttp { include /etc/nginx/mime.types; include /etc/nginx/sites-available/memverse-maintenance.conf; }\n' | sudo tee /tmp/nginx-check.conf >/dev/null && sudo nginx -t -c /tmp/nginx-check.conf`, then the same for `memverse-proxy.conf`.
- [ ] Note the filenames: on **fish-eagle** the enabled vhost is `/etc/nginx/sites-enabled/memverse.conf` (verified 2026-10-10); on **martial-eagle** it is `/etc/nginx/sites-enabled/memverse` (§7.7). The cutover commands below run on fish-eagle.
- [ ] A terminal open on each host, and this runbook open.

### T-0 on fish-eagle (window starts; write it down)
1. [ ] **Maintenance on.** `sudo rm /etc/nginx/sites-enabled/memverse.conf && sudo ln -s /etc/nginx/sites-available/memverse-maintenance.conf /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx`. Verify `curl -sI https://www.memverse.com/ | head -1` → `503`.
2. [ ] **Quiet and stop Sidekiq.** `sudo systemctl kill -s TSTP sidekiq-scheduler 'sidekiq-workers@*'`, wait ~30 s, `sudo systemctl stop sidekiq-scheduler 'sidekiq-workers@*'`, then `sudo systemctl disable sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2 sidekiq-workers@3` so they can never restart and double-run cron against the old DB. `redis-cli -n 0 LLEN queue:critical` etc. should be 0.
3. [ ] **Confirm no app writes:** `sudo passenger-status` shows 0 processing; `mysql -u root -p -e "SHOW PROCESSLIST"` shows only sleeping/your connections.
4. [ ] **Final dump:** run Appendix A.1. Note the sizes and `sha256sum` both files.
5. [ ] **Transfer:** `rsync -avP /var/backups/memverse/cutover_<TS>/ martial-eagle:/home/avitus/cutover/` then `sha256sum -c` on martial-eagle.

### On martial-eagle
6. [ ] **Restore:** Appendix A.2 (drops and recreates `memverse_production`; this is the rehearsal copy being replaced, nothing of value).
7. [ ] **Verify:** Appendix A.3 on both hosts, `diff`. Expected diff: `sessions` only. Any other difference = **stop and investigate** (rollback is still trivial at this point).
8. [ ] **Schema sanity:** `cd ~/memverse.com/current && RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rails db:migrate:status | grep -c down` → `0`.
9. [ ] **Sphinx:** `RAILS_ENV=production ~/.rvm/bin/rvm 3.2.6 do bundle exec rake ts:rebuild` (≈ 1–2 min; indexes `verses` and blog posts), then `sudo systemctl start memverse-searchd` if `ts:rebuild` left it stopped, and `ss -tln | grep 9312`.
10. [ ] **Start Sidekiq:** `cap production sidekiq:multi:start` from the Mac; confirm `Loaded 10 scheduled jobs` in `shared/log/sidekiq_scheduler.log` and `systemctl is-active sidekiq-scheduler sidekiq-workers@1 sidekiq-workers@2`.
11. [ ] **Restart Passenger** so it picks up the fresh DB (`touch ~/memverse.com/current/tmp/restart.txt`) and run Appendix A.4 with `--resolve`. Sign in via the `/etc/hosts` override and review a verse. **Go/no-go point.** No-go → §11.1.

### DNS flip
12. [ ] In Linode DNS Manager change the A records for `memverse.com` and `www.memverse.com` to **64.23.176.115** (TTL stays 300). `origin.memverse.com` follows via its CNAME.
13. [ ] Verify at the authority: `dig +noall +answer @ns1.linode.com www.memverse.com A` → `64.23.176.115`. Then from a public resolver: `dig @1.1.1.1 +short www.memverse.com`.

### fish-eagle after the flip
14. [ ] **Switch maintenance → reverse proxy:** `sudo rm /etc/nginx/sites-enabled/memverse-maintenance.conf && sudo ln -s /etc/nginx/sites-available/memverse-proxy.conf /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx`. Now a client still resolving the old IP is served by martial-eagle through fish-eagle. Verify: `curl -sI --resolve www.memverse.com:443:192.241.205.154 https://www.memverse.com/users/sign_in | head -1` → `200`.
15. [ ] **Freeze the old database** so nothing can write to it by accident: `mysql -u root -p -e "SET GLOBAL read_only = 1; SET GLOBAL super_read_only = 1;"` (reversible for rollback).
16. [ ] Remove the `/etc/hosts` override on the Mac. **Window ends; write down the time.**

---

## 10. Phase 5 — Post-cutover

- [ ] **Reissue TLS on martial-eagle** once `dig +short www.memverse.com` returns the new IP from a public resolver (within ~5–15 min): `sudo certbot certonly --webroot -w /var/www/certbot -d memverse.com -d www.memverse.com --key-type ecdsa` then `sudo nginx -t && sudo systemctl reload nginx`, and `sudo certbot renew --dry-run`. The copied renewal conf (nginx authenticator from certbot 0.31) is replaced by this.
- [ ] Watch for one hour: `tail -f shared/log/production.log`, `shared/log/nginx_error.log`, Sentry (new host tag), New Relic error rate and response time compared with the previous week.
- [ ] Confirm the next hourly `schedule_send_reminders` fired on the hour **UTC** and `last_reminder` dates look right (`rails runner 'puts User.where(last_reminder: Date.today).count'`, where `Date.today` is Pacific because of D3).
- [ ] Confirm the next day's `schedule_forum_review_notifier` (08:00 UTC) and `schedule_update_metrics` (12:00 UTC) ran; confirm the Tuesday 17:00 UTC quiz runs.
- [ ] Check `MemAvailable` on martial-eagle daily for a week; Ruby processes grow. Adjust Passenger pool / worker count if needed.
- [ ] After 48 h, raise the DNS TTL back to 3600 (not 86400).
- [ ] Update `documentation/DEPLOYMENT.md`, `deployment_scripts/README.md`, `CLAUDE.md` (server section) and the Capistrano docs to name martial-eagle; remove the `fish_eagle` stage when fish-eagle is gone.

---

## 11. Rollback

**11.1 Before the DNS flip (steps 1–11).** Trivial and loss-free: on fish-eagle re-enable `memverse.conf`, `systemctl enable --now sidekiq-scheduler sidekiq-workers@{1,2,3}`, reload nginx. Nothing was written anywhere else.

**11.2 Within the first hours after the flip.** Users have been writing to martial-eagle, so this is a *decision*, not a reflex:
1. On fish-eagle: `SET GLOBAL read_only = 0; SET GLOBAL super_read_only = 0;`, enable the maintenance vhost again, stop Sidekiq on martial-eagle.
2. Either accept the loss of writes made since step 12, or (if the window was short and the cause is not data-related) dump martial-eagle with Appendix A.1 and restore into fish-eagle 5.7. A dump taken by the 8.0 `mysqldump` contains `utf8mb3` and `utf8mb4_0900_ai_ci` names that 5.7 does not accept; use the **5.7 client on fish-eagle** to pull the dump over SSH tunnel (`mysqldump -h 127.0.0.1 -P <tunnel>` against martial-eagle) so the output is 5.7-flavoured, and restore with `--force` off. Rehearse this once in Phase 3 if you want it as a real option.
3. Point DNS back to 192.241.205.154 (5 min TTL), switch martial-eagle's `memverse` vhost to a reverse proxy toward fish-eagle (mirror of A.6) so stale-DNS clients land on the right data, and re-enable Sidekiq on fish-eagle.

**11.3 After a day.** No rollback; fix forward on martial-eagle. fish-eagle's 503/proxy configuration and read-only database stay as they are until decommissioning.

---

## 12. Phase 6 — Decommission fish-eagle (≥ 14 days after cutover)

- [ ] **Off-host backups first.** The existing `memverse-backup.timer` on martial-eagle pulls *from fish-eagle*; once Memverse lives on martial-eagle it is no longer off-host and will fail when fish-eagle dies. Replace it with a local `mysqldump --single-transaction` to a dated file plus a push to DigitalOcean Spaces (or another droplet/host), with a restore test. Do not destroy fish-eagle until a restore from the new backup has been proven.
- [ ] **realm.andyvitus.com is retired (D6):** no migration; remove its A record at Linode when fish-eagle goes. **assetcorrelation.com** has no nginx vhost on fish-eagle; archive `/home/avitus/assetcorrelation.com` with the final snapshot and drop it.
- [ ] **Migrate andyvitus.com** to martial-eagle (§12.1). It must be serving from martial-eagle, with its DNS switched, before fish-eagle is destroyed.
- [ ] Remove the `memverse-backup@martial-eagle` forced-command key from fish-eagle's `authorized_keys` (moot after destruction, but tidy).
- [ ] Stop the reverse proxy on fish-eagle, final DO snapshot, destroy the droplet, delete the pre-cutover snapshot after another month.
- [ ] Remove the `fish_eagle` Capistrano stage; update memory/docs; close the CLAUDE.md "Ubuntu 16.04" items.

### 12.1 andyvitus.com mini-migration (small; same stack)
andyvitus.com is a **Rails 7.2.2.2 / Ruby 3.2.6 / mysql2** app at `/home/avitus/andyvitus.com` (release `20250908012906`, Capistrano config in `config/deploy.rb` + `config/deploy/production.rb`, database `andyvitus_production`, `shared/` is 361 MB mostly bundle/storage), served by the same Passenger and the global `passenger_ruby` 3.2.6 wrapper on fish-eagle, over plain HTTP (port 80 only, no certificate). On martial-eagle everything it needs already exists after Phase 2 (user `avitus`, RVM 3.2.6, Passenger module, MySQL 8.0, certbot).
- [ ] Check `shared/storage` and `shared/public` for uploaded files (unlike Memverse it may have some; `rsync` them), then dump `andyvitus_production` with the A.1 pattern.
- [ ] Create its DB and user on martial-eagle, restore, deploy with its own Capistrano config (or `rsync` the release if it has no Capistrano), add an nginx vhost with `passenger_enabled on`, obtain a certificate (`certbot certonly --webroot ... -d andyvitus.com -d www.andyvitus.com`) and redirect 80 → 443 while at it.
- [ ] Lower its Linode TTLs alongside Phase 1, flip `andyvitus.com` and `www.andyvitus.com` A records to 64.23.176.115 any time after Memverse is stable, and remove `realm.andyvitus.com`.

---

## 13. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| MySQL 5.7 → 8.0: reserved words `rank` (5 columns), `groups` (table) | Low | App errors | ActiveRecord quotes identifiers; no bare raw SQL found; dev already on 9.6; **CI moved to 8.0 before the cutover (0.1)**. |
| MySQL 8.0 charset/collation: DB is `utf8`/`utf8_general_ci`, 32 tables `latin1` | Low | Mixed-collation errors on new tables | Create the DB with the same default (`utf8mb3`/`utf8mb3_general_ci`) and set the server default to match; the dump carries per-table charsets; `utf8` alias accepted with a deprecation warning. |
| MySQL `sql_mode` drift | Low | Different validation behaviour | Explicitly set to fish-eagle's mode minus the removed `NO_AUTO_CREATE_USER`. |
| Sphinx `indexer` cannot authenticate with `caching_sha2_password` | Medium | Search empty | Rehearsal step 3.5; fallback to `mysql_native_password` for the `memverse` user. |
| Time zone: `Date.today` semantics / cron shift | High if ignored | Verses due at the wrong time, quizzes 7 h off | D3: droplet set to America/Los_Angeles (§7.0) with `ENV['TZ']` left unset; cron pinned to UTC as a guard (0.2), verified as a no-op on fish-eagle first. |
| Droplet-wide Pacific time affects Mankunku / veetbot | Medium | Timers or jobs fire 7–8 h later; log timestamps change | §7.0 audit of timers, crons and unit files before `timedatectl`; restart the tenants afterwards. |
| Both Sidekiq schedulers running (double cron) | Low | Duplicate reminder emails/quizzes | fish-eagle's units are stopped **and disabled** at T-0 before martial-eagle's are started; rehearsal scheduler stopped before Phase 4. |
| Memory pressure on a shared box | Medium | OOM kills across three products | D2 resize to 16 GB; workers 3 → 2; Passenger pool capped; watch `MemAvailable`. |
| DNS TTL still 86400 at cutover | Medium | Up to 24 h of stragglers | Phase 1 ≥ 48 h ahead, verified at the authority; **fish-eagle reverse-proxies after the flip** so stragglers still work. |
| TLS mismatch after the flip | Low | Browser warnings | Live cert copied before cutover (valid to 2026-11-23); reissued by webroot right after. |
| OpenSSL 1.0.2 → 3.0 | Low | Native gem build or outbound TLS failures | Ruby 3.2.6 built against OpenSSL 3 in 7.5; rehearsal exercises Postmark, Sentry, New Relic, PubNub, ESV API. |
| Node 16 → 24 for asset precompile | Low | `terser` failure on deploy | Dev already runs Node 24; exercised in rehearsal 3.4. |
| Passenger gem module → apt module | Low | Vhost directive differences | Same directives; `passenger-config validate-install` in 7.4; rehearsal. |
| Capistrano's `thinking_sphinx:restart` vs the systemd `searchd` unit | Low | Two `searchd` processes or none | `Restart=on-failure`; pid-file based stop; `pgrep searchd` after every deploy for the first week. |
| Rehearsal scheduler sending real emails | Medium | Users get duplicate reminders | 3.6: stop the scheduler immediately after the check or use a Postmark sandbox token. |
| fish-eagle reboot (accidental) | Low | Rollback asset may not come back | Do not reboot it; do not apply updates to it. |
| Off-host backup silently broken after the move | High if forgotten | No backups | §12 first item, before decommission. |
| Rollback after users have written to martial-eagle | — | Data loss or complex reverse restore | §11.2; keep the smoke test (step 11) thorough so the go/no-go happens before DNS. |

---

## Appendix A — Scripts and staged configs

The files live in `deployment_scripts/migration/` (README there maps each to its install path); this appendix only says what each one does so the runbook above stays short.

- **A.1 `scripts/cutover_dump.sh`** (fish-eagle): consistent `mysqldump --single-transaction --hex-blob` of everything except the data of the dead `sessions` table, plus a schema-only dump of `sessions`, with SHA256SUMS. Prompts once for the MySQL root password via `mysql_config_editor` (a temporary login path, removed on exit; no quoting rules to get wrong). `--default-character-set=utf8mb4` is lossless for the `latin1` and `utf8` tables.
- **A.2 `scripts/cutover_restore.sh <dir>`** (martial-eagle, as root): verifies checksums, drops and recreates `memverse_production` as `utf8mb3`/`utf8mb3_general_ci`, loads the dump with `foreign_key_checks`/`unique_checks`/`sql_log_bin` off and `innodb_flush_log_at_trx_commit=2` for the duration, then reports the table count (expect 83).
- **A.3 `scripts/verify_counts.rb`** (both hosts via `rails runner`, then `diff`): row count, max id and max `updated_at` per table.
- **A.4 `scripts/smoke.sh <ip>`** (from a workstation, DNS-independent via `--resolve`): redirects, sign-in, forum, blog, admin, apidocs (`accessCode`), the verse-search route (redirects anonymous users; Sphinx needs a signed-in check, see 3.7), bot block, a fingerprinted asset, and certificate validity. Every request is bounded (20 s), every check is compared with its expected status, and the script **exits non-zero on any failure**, so it gates step 11.
- **A.5 `fish-eagle/memverse-maintenance.conf`**: 503 with `Retry-After` and the static page for the window.
- **A.6 `fish-eagle/memverse-proxy.conf`**: post-flip reverse proxy to martial-eagle with SNI, `X-Forwarded-*`, WebSocket upgrade headers and **upstream certificate verification** (`proxy_ssl_verify on` against the system CA bundle; see rehearsal step 3.10).

## Appendix B — Verification commands used to build this plan

Run again before Phase 4 if more than two weeks have passed:
- fish-eagle: `lsb_release -a`, `mysql --version`, `redis-server --version`, `passenger-config --version`, `grep passenger_root /etc/nginx/passenger.conf`, `cat ~/memverse.com/current/REVISION`, `du -sh ~/memverse.com/shared/*`, `redis-cli INFO keyspace`, `(echo stats; sleep 1) | nc 127.0.0.1 11211 | grep get_hits` (twice), `systemctl list-units 'sidekiq*'`, `sudo -n -l`.
- martial-eagle: `free -h`, `apt-cache policy mysql-server-8.0 redis-server sphinxsearch`, `ls /etc/nginx/sites-enabled`, `systemctl list-timers | grep memverse`, `ss -tln`.
- DNS: `dig +noall +answer @ns1.linode.com memverse.com A www.memverse.com A`.
- TLS: `echo | openssl s_client -connect www.memverse.com:443 -servername www.memverse.com | openssl x509 -noout -dates`.
