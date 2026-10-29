# Quiz system

The live Bible knowledge quiz and custom quizzes: data model, question types, the worker timeline,
the browser side, administration and debugging. Merged in October 2026 from
`QUIZ_SYSTEM_DOCUMENTATION.md`, `QUIZ_EXECUTION_TIMELINE.md`, `QUIZ_CHAMPION_BADGE.md` and
`LIVE_QUIZ_COUNTDOWN_REFRESH_FIX_OCTOBER_2025.md` (all in git history). Scheduling rules live in
[SIDEKIQ.md](./SIDEKIQ.md).

## Overview

- **Knowledge quiz** (`Quiz` id 1): public, multiple choice, run by the `KnowledgeQuiz` worker
  **Tuesday 17:00 UTC and Saturday 23:00 UTC** (`config/sidekiq_schedule.yml`). Users join at `/live_quiz`.
- **Custom quizzes** (`Quiz` id > 1): created by quizmasters for a group or church, with their own
  questions and `start_time`; run by the `ScheduledQuiz` worker, which an admin starts from the quiz
  dashboard. Users join at `/live_quiz/:quiz`.
- Questions and scoreboards travel over **PubNub**; live state lives in **Redis** through the
  `QuizSession` service (`app/services/quiz_session.rb`); nothing durable is kept in Redis.

## Data model

`quizzes`: `user_id` (creator), `name`, `description`, `quiz_questions_count`, `start_time`,
`quiz_length` (seconds, recomputed by `Quiz#update_length` whenever questions change).

`quiz_questions`: `quiz_id`, `question_no`, `question_type` (`mcq`, `recitation`, `reference`),
`passage`, `mc_question`, `mc_option_a`–`d`, `mc_answer`, `mcq_category`, `times_answered`,
`perc_correct`, `last_asked`, `supporting_ref` (an `Uberverse` id), `submitted_by`,
`approval_status` (`Pending`, `Approved`, `Rejected`), `rejection_code`.

Scopes on `QuizQuestion`: `mcq`, `recitation`, `reference`, `approved`, `pending`, `rejected`,
`fresh` (not asked for 6 months), `easy`/`medium`/`hard` (by `perc_correct`).

### Question types and time allocation (`QuizQuestion#time_allocation`)

| Type | Validation | Seconds allowed |
|---|---|---|
| `mcq` | question 8–300 chars, four options, one-letter answer | `0.4 × words in question + options, + 10` |
| `recitation` | `supporting_ref` required | `2.5 × words in the verse + 15` (24 wpm typing plus thinking time) |
| `reference` | `supporting_ref` required | 25 |

There is no fixed 30-second question; the worker sleeps for each question's own allocation and
sends it to the browser as `time_alloc`.

## Creating quizzes and questions

- Quizzes: `/quizzes/new` (CanCanCan: `can :manage, [Quiz, QuizQuestion]` for the `quizmaster` role).
- Questions: `/quiz_questions/new?quiz=ID`; anyone signed in can `create` a question and manage their
  own submissions; `/submit_question` is the public submission form; quizmasters approve or reject at
  `/quiz_question_approval`. Only `Approved` MCQs enter the knowledge-quiz pool.
- From a console: `Quiz.create!(user:, name:, description:, start_time:)` and
  `QuizQuestion.create!(quiz:, question_no:, question_type: "mcq", mc_question:, mc_option_a: ... mc_answer: "C", submitted_by:, approval_status: "Approved")`.

## Knowledge quiz timeline (`app/workers/knowledge_quiz.rb`)

The cron entry fires at the published time; the countdown users see targets this moment.

| Time | What happens |
|---|---|
| T+0:00 | Worker starts. Acquires an execution-window lock (`knowledge_quiz_lock_execution`, 5 min) and the quiz lock (`quiz_session:1:lock`, `QuizSession::LOCK_TIMEOUT` 3600 s). Status `In progress. Initializing...`; old session data cleared. Tweet "The Bible knowledge quiz is starting" and an iOS push. |
| T+0:00 → T+5:00 | Chat opens (Redis hash `chat-quiz-1` status `Open`, PubNub `chat_status` on channel `quiz-1`); 300 s of chat (30 s outside production). Status `In progress. Chat open. Wait for question.` |
| T+5:00 → ~T+25:00 | **25 questions** (5 outside production). Each is `QuizQuestion.mcq.approved.order(:last_asked).first` (falling back to questions of at most 300 characters), so the pool rotates least-recently-asked first and new approved questions go first; `last_asked` is set to today. The question is published over PubNub with its `time_alloc`, the worker sleeps that long, then publishes the scoreboard. |
| end | Status `Finished`. `perc_correct` and `times_answered` are updated from the answers; the final scoreboard is logged; a winner tweet is posted and the **Quiz Champion** badge (`Badge.where(name: 'Quiz Champion')`, created by migration `20250930222702`) is awarded with `award_badge`, which does not duplicate an existing award. Badge problems are logged and never abort the quiz. |
| end → +10:00 | Chat stays open 600 s (30 s outside production), then closes; locks released. |

Operations that talk to external services (tweet, PubNub publish, Redis cleanup) go through
`with_retry` (3 attempts, growing back-off). The worker has `retry: false`, so a crashed quiz is not
re-run. Session keys carry a 2-hour TTL (`QuizSession::DEFAULT_TTL`).

### Redis keys (`QuizSession`, prefix `quiz_session`)

`quiz_session:<quiz_id>:status` (hash: status, updated_at, metadata), `:lock`, `:participants` (set),
`:user:<user_id>` (hash: name, login, id, score), `:questions` (set), `:question:<n>` (hash).
`Quiz#status`/`Quiz#channel` still use the legacy `quiz<id>` hash (no dash), while the workers publish on PubNub channel `quiz-<id>` and keep the chat status in `chat-quiz-<id>`.
`QuizSession#cleanup_quiz_data` deletes `quiz_session:<id>:*`.

### Scoring

The browser POSTs each answer to `/record_score` (web) or `/api/v1/record_score` (OAuth) with
`quiz_id`, `usr_id`, `usr_name`, `usr_login`, `question_id`, `question_num`, `score`. A score of
`"false"` or 0 is ignored; otherwise `QuizSession#add_participant`, `#update_score` and
`#update_question_stats` run and the scoreboard the worker publishes after the question reflects it.

## Custom quizzes (`app/workers/scheduled_quiz.rb`)

`ScheduledQuiz#perform` looks for a quiz with `start_time` within the next minute, takes
`quiz_session:<id>:lock`, and runs the same open-chat / questions / scoreboard sequence with the
quiz's own questions, handling all three question types (recitation questions send the verse in
several translations). It is **not** on the cron schedule any more (the every-minute `schedule_quiz`
entry was removed on 2026-10-17 because it had been disabled only in the old server's Redis); an
admin starts it from `/admin/quiz_dashboards/:id` → **Start**. That action moves the quiz's
`start_time` to 30 seconds ahead (inside the worker's one-minute search window) and enqueues
`ScheduledQuiz` with `perform_async`, so a Sidekiq worker process must be running; the worker waits
until `start_time` and then runs the quiz. (Until October 2026 the button set `start_time` to *now*
and ran the worker inline, which never found the quiz because the window is `start_time > now`.)
PubNub channel is `quiz-<id>`; no tweet, push or badge.

## Browser side

`LiveQuizController#live_quiz` (`app/controllers/live_quiz_controller.rb`) always renders
`live_quiz_modern.html.erb`; the legacy `live_quiz.html.erb` is kept and rendered only with
`?legacy=true`. There is no `USE_MODERN_QUIZ_INTERFACE` flag.

Two JavaScript layers coexist and are coordinated:

- **Stimulus** `live-quiz` controller (`app/javascript/controllers/live_quiz_controller.js`) polls
  `GET /live_quiz/quiz_state/:id` (JSON from `LiveQuizController#quiz_state`, which classifies the
  Redis status into `preparing`, `ready`, `running`, `finished` or `waiting`), drives the question timer and
  calls `refreshPage()` (Turbo visit, or `location.reload()`) once the quiz is live.
- **jQuery** `QuizSchedule` (`app/assets/javascripts/live_quiz.js`) renders the schedule block
  (`Quiz.knowledge_quiz_schedule` → Tue 17:00 / Sat 23:00 UTC shown in local time) and the countdown
  to the worker start: updates every 5 s, every 1 s inside the last minute, shows "Preparing quiz..."
  in the last 20 s and "Loading quiz..." at zero, then reloads **3 s** after the target so the worker
  has written its status.

Coordination (October 2025 fix, after five attempts): jQuery exits early when a `live-quiz` Stimulus
element with `quiz-preparing-value="true"` is present; both layers share the
`sessionStorage` flag `quiz_reload_scheduled` (plus `quiz_preparation_<target>`), and all flags are
cleared **before** `window.location.reload()` so a reload cannot re-trigger itself. The controller
sets `@quiz_preparing` from the unified state (`preparing` or `ready`), not from a single status string.

`GET /live_quiz/till_start/:id.json` is the older polling endpoint (`{ "time": "+0h +5m +30s" }` before
start, `{ "status": ... }` during and after) and is still served.

## Administration

- `/admin/quiz_dashboards` (admins): list, `monitor`, `participants`, `start`/`stop` per quiz;
  `health_check`, `error_logs`, `statistics`, `schedule`, `bulk_manage` for the collection.
- `/admin/quiz_health/status`: Redis reachability, last run, next scheduled run.
- Sidekiq UI `/sidekiq` → Cron tab must show both `KnowledgeQuiz` entries. The other entries there (forum review notifications, tag-cloud refresh, reminders, metrics, passages) are expected too; see [SIDEKIQ.md](./SIDEKIQ.md). What must *not* appear is any extra quiz entry (a test quiz, a `schedule_quiz` leftover).
- API: `GET /api/v1/quizzes`, `/api/v1/quizzes/:id`, `/api/v1/quizzes/upcoming` (next knowledge quiz,
  from `Quiz.next_knowledge_quiz_time`, which checks Sidekiq's scheduled set and running jobs before
  the cron times). See [API.md](./API.md).

## Running a quiz by hand

Never add a test entry to `config/sidekiq_schedule.yml` (the schedule spec rejects it; see
SIDEKIQ.md). From a console on the target host:

```ruby
KnowledgeQuiz.perform_async        # now
KnowledgeQuiz.perform_in(2.hours)  # later
```

In production this tweets, pushes to every iOS user and awards a badge exactly like the scheduled run.

## Debugging

```bash
rake quiz_debug:check_status   # print the quiz status and lock keys in Redis
rake quiz_debug:clear_status   # clear them (after an interrupted quiz)
bin/quiz-cleanup               # same clean-up as a script
redis-cli KEYS 'quiz_session:*'
redis-cli HGETALL quiz_session:1:status
grep '===>' log/sidekiq_workers.log | tail -50          # worker narrative (shared/log/sidekiq_worker_1.log in production)
```

Common causes: the worker could not take the lock (a previous run was interrupted; clear it), no
approved MCQs, PubNub credentials missing, or the scheduler loaded the quiz entry more than once.
