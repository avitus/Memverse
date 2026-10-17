# Bible Knowledge Quiz Firing Every 40 Minutes (October 2026)

## Symptom

From 2025-11-06 the live Bible knowledge quiz (`KnowledgeQuiz`, `app/workers/knowledge_quiz.rb`)
started at :00 and :40 past every hour in production instead of twice a week
(Tuesday 17:00 UTC and Saturday 23:00 UTC). Each spurious run:

- posted an admin tweet announcing the quiz,
- sent an iOS push notification to every user,
- burned `last_asked` on 25 quiz questions,
- awarded a Quiz Champion badge to the winner.

It was found on 2026-10-16 while investigating quiz frequency ahead of the martial-eagle cutover.

## Root cause

Commit `4939b431` ("Working on quiz start", 2025-11-06) added a test entry to
`config/sidekiq_schedule.yml`:

```yaml
schedule_knowledge_quiz_test:
  cron: "*/40 * * * * UTC"
  class: "KnowledgeQuiz"
  queue: critical
  active_job: false
  active: false        # Explicitly mark as inactive
```

`active: false` was meant to switch the entry off. It did nothing.

### Why `active: false` was inert

sidekiq-cron (2.4.0, `lib/sidekiq/cron/job.rb`, `Sidekiq::Cron::Job#initialize`) reads a fixed set of
keys from each entry: `cron`, `class`, `queue`, `active_job`, `status`, `description`, `args`,
`namespace`, `symbolize_args`, `date_as_argument`, `retry` (plus a few internal ones). Every other key
is silently ignored. There is no `active` key. A job is enabled unless its `status` is `disabled`, so
the entry loaded as an enabled job and fired every 40 minutes.

The only way to switch an entry off while keeping it in the file is:

```yaml
  status: disabled
```

### Why removing the YAML line alone would not have stopped it

`config/initializers/sidekiq.rb` loaded the schedule with the non-bang
`Sidekiq::Cron::Job.load_from_hash(schedule)`. That call only adds or updates the jobs named in the
hash. A job that is already registered in Redis but no longer in the YAML is left alone, so it keeps
firing across every deploy and scheduler restart. Deleting the test entry from the file would have
changed nothing in production.

The bang form, `load_from_hash!(schedule, source: "schedule")`, first calls `destroy_removed_jobs`,
which destroys every Redis job whose stored `source` is `"schedule"` and whose name is not in the new
hash, then loads the hash with `source: "schedule"` so the jobs it saves are eligible for that cleanup
next time.

There is one catch. Jobs saved by the old non-bang call (which passed no `source:`) were stored with
`source: "dynamic"`. `destroy_removed_jobs` ignores dynamic jobs, so the stale
`schedule_knowledge_quiz_test` job will **not** be destroyed by the first boot with the new code.
It needs the one-time cleanup below. After that, every job in Redis carries `source: "schedule"` and
future removals from the YAML take effect at the next scheduler boot.

## The fix (PR carrying this document)

1. `config/sidekiq_schedule.yml`: the test entry is deleted outright, and a comment at the top explains
   that unknown keys are ignored, `status: disabled` is the only off switch, and removed entries are
   destroyed at boot.
2. `config/initializers/sidekiq.rb`: `load_from_hash(schedule)` is now
   `load_from_hash!(schedule, source: "schedule")`.
3. `spec/config/sidekiq_schedule_spec.rb` now fails if:
   - any entry uses a key sidekiq-cron 2.4 does not understand (`active: false` fails with a message
     pointing at `status: disabled`);
   - the `KnowledgeQuiz` entries together fire anything other than exactly twice in any 7-day window
     (occurrences are enumerated with Fugit from a fixed UTC start and checked over a sliding window);
   - a `KnowledgeQuiz` entry is present but `status: disabled`;
   - the initializer does not call `load_from_hash!` with `source: "schedule"`.
   The existing UTC-pinning assertions are kept.
4. `documentation/SIDEKIQ_MODERNIZATION_CHANGELOG.md` records that the earlier switch to the non-bang
   form is reverted; the bang form exists and works in sidekiq-cron 2.4.0.

## One-time production cleanup

Run this **once**, after the deploy that carries this change (the code fix alone does not remove the
stale dynamic job):

```bash
ssh memverse 'cd /home/avitus/memverse.com/current && /home/avitus/.rvm/bin/rvm 3.2.6 do bundle exec rails runner -e production "puts Sidekiq::Cron::Job.destroy(\"schedule_knowledge_quiz_test\")"'
```

It prints `true` when the job was found and destroyed, `false` when it was already gone. Then confirm in
the Sidekiq UI Cron tab that only `schedule_knowledge_quiz_tuesday` and `schedule_knowledge_quiz_saturday`
exist for `KnowledgeQuiz`.

If the job was disabled in Redis as a stopgap (`Sidekiq::Cron::Job.find("schedule_knowledge_quiz_test").disable!`),
that state persists across restarts but still leaves the job registered. The cleanup above is still needed.

## How to run a test quiz safely in future

Do not add a test schedule to `config/sidekiq_schedule.yml`. That file is the production schedule and the
spec will reject a third `KnowledgeQuiz` entry.

**Preferred: enqueue the worker once by hand** from a Rails console on the target server. It runs the
same code path as the cron job, once, and leaves nothing behind in the cron table.

```ruby
KnowledgeQuiz.perform_async              # start now
KnowledgeQuiz.perform_in(2.hours)        # or start at a convenient time
```

Remember that on production this still tweets, pushes to every iOS user and awards a badge, exactly as
the scheduled quiz does.

**Alternative for a development or staging checkout only:** add an entry with `status: disabled` to the
schedule file of that checkout, boot the scheduler, enable the job from the Sidekiq UI Cron tab when you
want it to run, and disable it again afterwards. Remove the entry from the file before it is committed:
the spec fails on a disabled `KnowledgeQuiz` entry on purpose, so it cannot reach `main`. Because the
loader is now the bang form, deleting the entry and restarting the scheduler also removes the job from
that checkout's Redis.

## Related

- `documentation/CRITICAL_SIDEKIQ_CRON_FIX.md`: the 2025 incident where `active_job: true` on plain
  `Sidekiq::Worker` classes stopped every cron job from enqueuing. Same lesson: sidekiq-cron does not
  validate the schedule file, so the spec has to.
- `documentation/SIDEKIQ_MODERNIZATION_CHANGELOG.md`
- `spec/config/sidekiq_schedule_spec.rb`
