# Deployment

Capistrano 3.19.2 deploys the `main` branch to the production host **martial-eagle**. This page
replaces the August 2025 version and the credentials guides (`MODERN_CREDENTIALS_DEPLOYMENT.md`,
`DATABASE_CREDENTIALS_SETUP.md`, in git history). For Sidekiq details see [SIDEKIQ.md](./SIDEKIQ.md);
for the migration that produced this setup see
`plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md`.

## Production server

| | |
|---|---|
| Host | martial-eagle, DigitalOcean sfo3, Ubuntu 24.04, IPv4 `64.23.176.115` |
| Stage file | `config/deploy/production.rb` (addresses the host **by IP** so DNS can never decide where a deploy lands) |
| Deploy user / path | `avitus`, `/home/avitus/memverse.com` (`current`, `releases`, `shared`) |
| Ruby | 3.2.6 via RVM at `/home/avitus/.rvm` (`before :starting` fails the deploy if `rvm current` is not 3.2.6) |
| Node (asset precompile only) | nvm v24.21.0, on `PATH` through `:default_env` |
| Web | nginx 1.24 + Phusion Passenger module; restart is `touch tmp/restart.txt` |
| Database | MySQL 8.0, `memverse_production`, local socket |
| Redis | 7.0, DB 0 for Sidekiq |
| Search | Sphinx `searchd` under the `memverse-searchd` systemd unit |
| Background jobs | systemd units `sidekiq-scheduler`, `sidekiq-workers@1`, `sidekiq-workers@2` |
| TLS | Let's Encrypt via certbot (webroot `/var/www/certbot`) |
| DNS | Linode; `memverse.com` and `www` A records → `64.23.176.115`, TTL 3600 |
| Backups | nightly `memverse-backup.timer` on the host dumps the database and rclones it off-host, encrypted |
| Monitoring | Sentry (org `veetle`, [ERROR_MONITORING.md](./ERROR_MONITORING.md)), New Relic (`config/newrelic.yml`) |
| Other tenants | mankunkujazz.com and veetbot.com share the droplet (2 Sidekiq workers, not 3, for that reason) |

The old host **fish-eagle** (`192.241.205.154`, Ubuntu 16.04) served production until the cutover on
2026-10-17. It still exists as the `fish_eagle` Capistrano stage (`config/deploy/fish_eagle.rb`) and as
a reverse proxy for stale DNS until it is decommissioned; do not deploy to it except for an emergency
during the overlap.

`config/deploy/staging.rb` and `config/deploy/production_rails7.rb` are leftovers from the Rails 7
upgrade and are not used.

## Everyday commands

```bash
cap production deploy                       # standard deploy (runs migrations via capistrano/rails)
cap production deploy:check                 # verify SSH, directories and linked files
cap production deploy:rollback              # previous release (code only)
cap production sidekiq:multi:status         # scheduler and worker units
cap production sidekiq:multi:restart        # quiet, wait 10 s, restart
cap production memverse:searchd:restart     # regenerate Sphinx config and restart searchd
SKIP_SIDEKIQ_START=1 cap production deploy  # deploy but leave Sidekiq stopped
SIDEKIQ_WORKERS=2 cap production deploy     # worker count (default 2; sudoers lists exactly two)
cap fish_eagle deploy                       # legacy host, emergencies only
```

Before deploying: run the suites locally (`bundle exec rspec`, `npm run test:run`,
`bundle exec cucumber features`), make sure `main` is pushed and your local `main` is current
(Capistrano clones from GitHub, `git@github.com:avitus/Memverse.git`), and confirm CircleCI ran a real
pipeline for the merge (`main` is unprotected; a missing check is not a pass).

## What a deploy does

`config/deploy.rb`, `config/deploy/production.rb` and `lib/capistrano/tasks/*.rake`, in order:

1. `deploy:starting` → `check_rails_7` (RVM Ruby check) and **`sidekiq:multi:stop`**
   (`systemctl stop sidekiq-scheduler`, `stop 'sidekiq-workers@*'`).
2. Checkout of `main` into a new `releases/<timestamp>`; `REVISION` is written there (Sentry reads it
   as the release).
3. Linked files and directories are symlinked from `shared/`: **`config/master.key`** is the only
   linked file; linked dirs are `log`, `tmp/pids`, `tmp/cache`, `tmp/sockets`, `public/assets`,
   `public/ckeditor_assets`, `public/uploads`, `storage`.
4. `bundle install --deployment --quiet` without `development test`, into `shared/bundle`
   (`NOKOGIRI_USE_SYSTEM_LIBRARIES=1`); `deploy:check:credentials` (`credentials_check.rake`) confirms
   `master.key` decrypts the credentials and that `database.password` is present, before migrations.
5. `deploy:assets:precompile` is overridden to run `rails assets:clobber` then
   `rails assets:precompile` (`keep_assets 2`).
6. `deploy:migrate`.
7. `deploy:publishing` → `deploy:restart` (`touch current/tmp/restart.txt`), then
   `deploy:published` → `clear_cache` (`Rails.cache.clear`) and **`sidekiq:multi:start`** unless
   `SKIP_SIDEKIQ_START=1`.
8. `deploy:finishing` → `thinking_sphinx:index`, then **`memverse:searchd:restart`**
   (`lib/capistrano/tasks/memverse_searchd.rake`: `ts:configure`, `ts:stop` for any searchd started
   outside systemd, `systemctl restart memverse-searchd`, then fail the deploy unless the unit is active
   and port 9312 answers within 30 s), then `deploy:cleanup` (keeps 5 releases).

The `capistrano-sidekiq` gem is not required in the `Capfile` (and `:sidekiq_default_hooks` is false
for good measure); everything Sidekiq-related is in `lib/capistrano/tasks/sidekiq_multi.rake`. The deploy user has no general
sudo: `/etc/sudoers.d/avitus-memverse` allows exactly the `systemctl` and `journalctl` command strings
those tasks send (and `systemctl reload nginx`). Unit files are installed by root, so
`sidekiq:multi:setup` and `sidekiq:multi:enable` are not used on this host.

## Credentials

Secrets live in `config/credentials.yml.enc`, decrypted with `config/master.key`
(`shared/config/master.key` on the server, mode 600, never committed). Edit with
`EDITOR="nano" rails credentials:edit`. Keys in use:

```yaml
secret_key_base: ...
database:
  username: memverse      # optional, defaults to memverse
  password: ...
  host: localhost         # optional
postmark:
  api_token: ...
```

`config/database.yml`'s `production` block reads `Rails.application.credentials.dig(:database, ...)`
(username default `memverse`, host default `localhost`, socket `/var/run/mysqld/mysqld.sock`, pool
`RAILS_MAX_THREADS` or 30). There is **no** shared `database.yml` and **no** `DATABASE_*` environment
variable on the server; `secrets.yml` is gone. `POSTMARK_API_TOKEN` in the environment overrides the
credential if set (`config/environments/production.rb`), but nothing sets it in production.

To install a new master key: `scp config/master.key avitus@64.23.176.115:memverse.com/shared/config/`,
then `cap production deploy:check:credentials`.

## After a deploy

- `https://www.memverse.com`: sign in, review a verse, open `/forum` and `/blog`.
- `cap production sidekiq:multi:status`; the scheduler log should show `Loaded 8 scheduled jobs`.
- Sentry for new issue types; `shared/log/production.log` and `shared/log/nginx_error.log` on the host.
- Search: `systemctl is-active memverse-searchd` and a verse search in the UI.

## Rollback

`cap production deploy:rollback` relinks the previous release, restarts Passenger and Sidekiq and
reindexes Sphinx. It does not undo migrations; if a migration was destructive, `ssh` in first and run
`bin/rails db:rollback RAILS_ENV=production` under `rvm 3.2.6 do` in `current`.

## One-time host setup

The server-side configuration that was installed during the migration (MySQL overrides, sudoers,
`memverse-searchd.service`, nginx vhosts, logrotate, backup script) is kept in
`deployment_scripts/migration/` with a table of where each file is installed; the Sidekiq unit
templates are `deployment_scripts/sidekiq-scheduler.service` and `sidekiq-workers@.service`.
Rebuilding the host from scratch follows the runbook in
`plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md` §7.
