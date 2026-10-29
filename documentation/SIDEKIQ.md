# Sidekiq background jobs

Memverse runs background work on Sidekiq 7.3 with sidekiq-cron 2.4 and Redis. This document covers
the process model, the configuration files, every worker, the production schedule and its rules,
deployment, and monitoring. Merged in October 2026 from `SIDEKIQ_BACKGROUND_JOBS_DOCUMENTATION.md`,
`SIDEKIQ_MONITORING.md`, `SIDEKIQ_SETUP.md`, `SIDEKIQ_DUPLICATE_QUIZ_FIX.md`,
`CAPISTRANO_SIDEKIQ_DEPLOYMENT.md`, `QUIZ_CRON_DUPLICATE_RUNS_2026-10.md`,
`CRITICAL_SIDEKIQ_CRON_FIX.md` and `ACTIVEJOB_SIDEKIQ_ISSUE.md` (all in git history).

## Process model: one scheduler, N workers

Two kinds of Sidekiq process run from the same code:

| | Scheduler | Worker |
|---|---|---|
| Config file | `config/sidekiq_scheduler.yml` | `config/sidekiq_workers.yml` |
| Instances | exactly **one** | 1 locally, 2 in production (`sidekiq-workers@1`, `@2`) |
| Concurrency | 5 | 25 |
| Queues (weight) | `critical` 2, `scheduler` 5, `low` 1 | `critical` 5, `high` 3, `default` 2, `low` 1 |
| Loads cron jobs | yes (`:scheduler: true`, `SIDEKIQ_SCHEDULER=true`) | no (`:scheduler: false`) |
| Log file | `log/sidekiq_scheduler.log` | `log/sidekiq_workers.log` (production: `sidekiq_worker_N.log`) |

Only the scheduler registers the cron schedule in Redis. Before this split every worker process
loaded the schedule and the Bible quiz was announced several times per run. The initializer decides
with `ENV['SIDEKIQ_SCHEDULER'] == 'true' || config[:scheduler] == true || ARGV.include?('--scheduler')`.

Locally, `./bin/dev` starts everything through foreman and the `Procfile`:

```
web:       rails s -p 3000
scheduler: bundle exec sidekiq -C config/sidekiq_scheduler.yml
worker:    bundle exec sidekiq -C config/sidekiq_workers.yml
```

`bin/dev` also starts MySQL and Redis if they are not running and creates the log files. The Sidekiq
UI is then at http://localhost:3000/sidekiq and the cron tab at http://localhost:3000/sidekiq/cron.

`config/sidekiq.yml` is the generic single-process configuration (queue weights `critical` 8,
`high` 4, `default` 2, `low` 1; concurrency 25, 5 in development, 2 in test; dead jobs kept 6 months;
`max_retries` 25; Redis pool `SIDEKIQ_REDIS_POOL_SIZE`, default 30). Use it only when running one
process by hand with `bundle exec sidekiq -C config/sidekiq.yml`.

## Queues

| Queue | Used by |
|---|---|
| `critical` | `KnowledgeQuiz`, `ScheduledQuiz` (live quiz, time-sensitive) |
| `high` | `SendReminders`, `ForumReviewNotifier` |
| `default` | `UpdateMetrics`, `VerseWebCheck`, anything enqueued without a queue, Active Job |
| `low` | `RefreshTagCloud`, `UpdateSubsections`, `SubsectionPassages` |
| `scheduler` | reserved for the scheduler process; nothing is enqueued to it today |

## `config/initializers/sidekiq.rb`

- **Redis**: `REDIS_URL` (default `redis://127.0.0.1:6379/0`), pool size `SIDEKIQ_REDIS_POOL_SIZE`
  (default 30) for servers and 5 for clients, `pool_timeout` 5 s, read/write timeouts 5 s, connect 2 s.
- **Logging**: a file logger on `log/sidekiq.log` (JSON lines in production, plain text otherwise);
  in development it also broadcasts to stdout.
- **Error handlers**: log the exception, its context and backtrace; a `fatal` line is added when
  `KnowledgeQuiz` or `SendReminders` fails. Sentry receives job failures through `sentry-sidekiq`,
  see [ERROR_MONITORING.md](./ERROR_MONITORING.md).
- **Timing middleware**: logs `SLOW JOB` when a job exceeds its threshold (600 s for the quiz workers,
  120 s for `SendReminders`, 300 s for `UpdateMetrics`/`UpdateSubsections`, 60 s for
  `RefreshTagCloud`/`SubsectionPassages`, 30 s otherwise) and writes per-class counters and the last
  duration into `Rails.cache` under `sidekiq:jobs:*`, plus `sidekiq:queue:<name>:last_processed`.
- **Cron loading** (scheduler only): `Sidekiq::Cron::Job.load_from_hash!(schedule, source: "schedule")`.
  The bang form first destroys every job in Redis whose source is `"schedule"` and whose name is no
  longer in the YAML, so **deleting an entry from the file removes it at the next scheduler boot**.
  In production a load failure raises and stops the process.
- **Startup checks**: warns when the dead set holds more than 1000 jobs; writes
  `sidekiq:server:last_startup` and `sidekiq:server:status` to the cache for the health dashboard.
- **Defaults**: `Sidekiq.default_job_options = { 'queue' => 'default', 'retry' => 3, 'backtrace' => true }`.

`config/environments/production.rb` sets `config.active_job.queue_adapter = :sidekiq`. Without it
Rails falls back to the in-process `:async` adapter; in September 2025 that line was missing and
`deliver_later` mail ran inside Passenger until the web queue filled ("This website is under heavy
load"). `rake sidekiq:health_check` prints the adapter as its first check.

## Workers (`app/workers/`)

All workers are plain `Sidekiq::Worker` classes, not Active Job classes.

| Worker | Queue | Retry | Trigger | What it does |
|---|---|---|---|---|
| `KnowledgeQuiz` | critical | no | cron Tue 17:00 / Sat 23:00 UTC | Runs the live Bible knowledge quiz (quiz id 1): opens chat, asks 25 questions (5 outside production), tweets start and winner, awards the Quiz Champion badge. Locks in Redis prevent a second concurrent run. See [QUIZ_SYSTEM.md](./QUIZ_SYSTEM.md). |
| `ScheduledQuiz` | critical | no | on demand: `Admin::QuizDashboardsController#start` calls `ScheduledQuiz.new.perform` | Finds a custom quiz (`id > 1`) starting within the next minute and runs it. Its every-minute cron entry (`schedule_quiz`) was removed on 2026-10-17. |
| `SendReminders` | high | no | cron hourly | Deletes 2-day-old unconfirmed users, then emails up to 8 progression reminders. See [EMAIL.md](./EMAIL.md). |
| `ForumReviewNotifier` | high | no | cron daily 08:00 UTC | Tells admins about forum posts awaiting moderation. Retry is off because failures flooded the log. |
| `UpdateMetrics` | default | yes | cron daily 12:00 UTC | `DailyStats.update` for the admin metrics. |
| `RefreshTagCloud` | low | no | cron 1 Mar / 1 Sep 01:05 UTC | Rebuilds the verse tag cloud. |
| `UpdateSubsections` | low | no | cron 1 Mar / 1 Sep 01:05 UTC | Recomputes `subsection_end` probabilities for passage verses. |
| `SubsectionPassages` | low | no | cron 2 Mar / 2 Sep 01:05 UTC | Auto-subsections active users' passages, using the day-old probabilities. |
| `VerseWebCheck` | default | default (3) | `Verse` `after_commit` when a new verse is not yet verified | Compares the stored text with the web text and sets `verified` when they match. |

Run any worker once from a console with `WorkerName.perform_async(args)` (or `perform_in(2.hours)`).

## Production schedule (`config/sidekiq_schedule.yml`)

Eight entries, all in UTC, all `active_job: false`:

| Entry | Cron | Class | Queue |
|---|---|---|---|
| `schedule_knowledge_quiz_tuesday` | `0 17 * * 2 UTC` | `KnowledgeQuiz` | critical |
| `schedule_knowledge_quiz_saturday` | `0 23 * * 6 UTC` | `KnowledgeQuiz` | critical |
| `schedule_forum_review_notifier` | `0 8 * * * UTC` | `ForumReviewNotifier` | high |
| `schedule_refresh_tag_cloud` | `5 1 1 3,9 * UTC` | `RefreshTagCloud` | low |
| `schedule_send_reminders` | `0 * * * * UTC` | `SendReminders` | high |
| `schedule_update_metrics` | `0 12 * * * UTC` | `UpdateMetrics` | default |
| `schedule_update_subsections` | `5 1 1 3,9 * UTC` | `UpdateSubsections` | low |
| `schedule_subsection_passages` | `5 1 2 3,9 * UTC` | `SubsectionPassages` | low |

### Rules for editing the schedule file

These rules each come from a production incident; `spec/config/sidekiq_schedule_spec.rb` enforces them.

1. **Never set `active_job: true`.** The workers are `Sidekiq::Worker` classes. With `active_job: true`
   sidekiq-cron calls `perform_later`, which silently enqueues nothing; every cron job was dead for
   about three years until this was found in 2025. Keep the explicit `active_job: false`.
2. **`status: disabled` is the only off switch.** sidekiq-cron ignores keys it does not know
   (`active: false` does nothing). A test entry with `active: false`, added in November 2025, ran the
   public quiz every 40 minutes for eleven months.
3. **Removing an entry removes the job**, because the initializer uses `load_from_hash!` with
   `source: "schedule"`. Jobs that were created by the old non-bang loader carry
   `source: "dynamic"` and must be destroyed once by hand (`Sidekiq::Cron::Job.destroy("name")`).
   A job disabled only in Redis does not survive a fresh Redis (this is why `schedule_quiz` revived on
   the new server and was deleted instead).
4. **Do not add test schedules.** The spec rejects a third `KnowledgeQuiz` entry and any
   `KnowledgeQuiz` entry that is disabled. To run a quiz once, use the console on the target host:
   `KnowledgeQuiz.perform_async` (or `perform_in`). In production that still tweets, pushes to every
   iOS user and awards a badge.
5. **Pin every cron line to UTC** (`... UTC`), as above.

The scheduler logs `[SIDEKIQ SCHEDULER] Loaded 8 scheduled jobs:` followed by one line per entry at
boot; a worker logs `[SIDEKIQ WORKER] This process will NOT handle cron jobs`.

## Production (martial-eagle)

Sidekiq runs as system-level systemd units installed from `deployment_scripts/sidekiq-scheduler.service`
and `deployment_scripts/sidekiq-workers@.service`:

- `sidekiq-scheduler` and `sidekiq-workers@1`, `sidekiq-workers@2`
  (`ExecStart=/home/avitus/.rvm/bin/rvm 3.2.6 do bundle exec sidekiq -e production -C config/sidekiq_<role>.yml`,
  `WorkingDirectory=/home/avitus/memverse.com/current`, user `avitus`).
- stdout/stderr append to `/home/avitus/memverse.com/shared/log/sidekiq_scheduler.log` and
  `sidekiq_worker_<N>.log`; `logrotate` keeps 14 daily copies. `journalctl` therefore shows only
  start/stop lines.
- The unit files were installed and enabled **by root** during the migration; the deploy user cannot
  write them, so `cap production sidekiq:multi:setup` and `sidekiq:multi:enable` are not used there.
  `/etc/sudoers.d/avitus-memverse` (`deployment_scripts/migration/martial-eagle/sudoers-avitus-memverse`)
  allows exactly the `systemctl`/`journalctl` strings the Capistrano tasks send, for two worker
  instances. Adding a third worker means adding its lines there, enabling `sidekiq-workers@3` as root,
  and deploying with `SIDEKIQ_WORKERS=3`.

Capistrano (`lib/capistrano/tasks/sidekiq_multi.rake`, `set :sidekiq_default_hooks, false`):

| Task | Does |
|---|---|
| `cap production sidekiq:multi:status` | `systemctl status` of the scheduler and all workers |
| `cap production sidekiq:multi:restart` (alias `sidekiq:restart`) | TSTP (quiet) all units, wait 10 s, restart scheduler then workers |
| `cap production sidekiq:multi:rolling_restart` | quiet and restart one worker at a time, scheduler last |
| `cap production sidekiq:multi:stop` / `:start` | stop everything / start scheduler and `SIDEKIQ_WORKERS` workers |
| `cap production sidekiq:multi:logs` | last 50 journal lines of scheduler and worker 1 |

Every deploy stops Sidekiq `before deploy:starting` and starts it `after deploy:published`.
`SKIP_SIDEKIQ_START=1 cap production deploy` leaves it stopped (used before the cutover so the new
host would not run jobs against rehearsal data). The worker count comes from the stage's
`:sidekiq_workers` (production: `ENV.fetch('SIDEKIQ_WORKERS', 2)`).

Quick checks on the server:

```bash
sudo systemctl status sidekiq-scheduler --no-pager
sudo systemctl status 'sidekiq-workers@*' --no-pager
tail -f /home/avitus/memverse.com/shared/log/sidekiq_scheduler.log
tail -f /home/avitus/memverse.com/shared/log/sidekiq_worker_1.log
cd /home/avitus/memverse.com/current && /home/avitus/.rvm/bin/rvm 3.2.6 do bundle exec rails runner -e production 'puts Sidekiq::Cron::Job.all.map(&:name)'
```

The last command must print each of the eight names once.

## Monitoring

- **Sidekiq Web** at `/sidekiq` (admins only, via a Devise route constraint), including the Cron tab.
- **Health dashboard** at `/admin/sidekiq_health/dashboard` (auto-refreshes every 30 s), with
  `/admin/sidekiq_health/health_check` (JSON, 200 or 503) and `/admin/sidekiq_health/metrics` (JSON),
  and POST actions to clear or retry failed jobs and to pause/resume a queue
  (`app/controllers/admin/sidekiq_health_controller.rb`).
- **Quiz health** at `/admin/quiz_health/status` and the quiz dashboard under `/admin/quiz_dashboards`.
- **Rake**: `rake sidekiq:health_check` (starts with the Active Job adapter, then Sidekiq state) and `rake sidekiq:monitor`.
- **Redis**: Sidekiq uses DB 0 of the local Redis. Nothing durable lives there: queues, the cron
  table (reloaded from YAML at scheduler boot), quiz session keys (`quiz_session:*`, see
  QUIZ_SYSTEM.md) and cache entries.

## Troubleshooting

| Symptom | Check |
|---|---|
| Cron jobs not firing | Is `sidekiq-scheduler` active? Does its log show `Loaded 8 scheduled jobs`? Does `Sidekiq::Cron::Job.all` list them with `status: enabled`? |
| A job fires more often than scheduled | More than one scheduler process, or a stale `source: "dynamic"` job in Redis (destroy it by hand). |
| Jobs queued but not processed | Workers down, or the job's queue is not in `sidekiq_workers.yml`. |
| `deliver_later` mail runs in the web process | `config.active_job.queue_adapter` is not `:sidekiq`. |
| Quiz "already running" | A previous run left `quiz_session:1:lock`; `rake quiz_debug:check_status` / `quiz_debug:clear_status` or `bin/quiz-cleanup`. |
