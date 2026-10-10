# fish-eagle → martial-eagle migration files

Canonical copies of the server-side configuration and scripts referenced by
`documentation/plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md`.
The plan is the runbook; these files are what it installs. Section numbers below refer to it.

| Path | Installs to | Plan § |
|---|---|---|
| `martial-eagle/mysql-zz-memverse.cnf` | `/etc/mysql/mysql.conf.d/zz-memverse.cnf` | 7.4 |
| `martial-eagle/sudoers-avitus-memverse` | `/etc/sudoers.d/avitus-memverse` (0440, `visudo -cf`) | 7.3 |
| `martial-eagle/memverse-searchd.service` | `/etc/systemd/system/memverse-searchd.service` | 7.6 |
| `martial-eagle/passenger-memverse.conf` | `/etc/nginx/conf.d/passenger-memverse.conf` | 7.7 |
| `martial-eagle/nginx-memverse.conf` | `/etc/nginx/sites-available/memverse` | 7.7 |
| `martial-eagle/logrotate-memverse` | `/etc/logrotate.d/memverse` | 7.7 |
| `fish-eagle/memverse-maintenance.conf` | `/etc/nginx/sites-available/memverse-maintenance.conf` | 9, A.5 |
| `fish-eagle/memverse-proxy.conf` | `/etc/nginx/sites-available/memverse-proxy.conf` | 9, A.6 |
| `fish-eagle/maintenance-index.html` | `/var/www/maintenance/index.html` | 9 |
| `scripts/cutover_dump.sh` | run on fish-eagle | 9, A.1 |
| `scripts/cutover_restore.sh` | run as root on martial-eagle | 9, A.2 |
| `scripts/verify_counts.rb` | `rails runner` on both hosts, then `diff` | 9, A.3 |
| `scripts/smoke.sh` | run from a workstation, DNS-independent | 9, A.4 |

The Sidekiq unit templates stay where Capistrano expects them: `deployment_scripts/sidekiq-scheduler.service`
and `deployment_scripts/sidekiq-workers@.service` (installed by `cap production sidekiq:multi:setup`).
