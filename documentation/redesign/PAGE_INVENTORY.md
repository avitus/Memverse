# Memverse Page Inventory

Compiled 2026-10-17 from `rails routes`, `app/views`, the navigation partials, the mailers,
and **seven days of production traffic (2026-10-10 to 2026-10-17)**. This is the input to the
redesign; see `DESIGN_BRIEF.md` alongside it.

## Where the numbers come from

| Source | Window | What it gives |
|---|---|---|
| `shared/log/production.log*` on fish-eagle | 7 days | Every request as `Controller#action` + format + client IP. Page loads and unique IPs per page. |
| `shared/log/nginx_access.log*` on fish-eagle | 7 days | User agents (device, browser, bots). |
| `daily_stats` table + `users` / `memverses` tables | point in time | Registered, active, new users; verse counts; language, translation, reminder settings. |

Google Analytics on the site is a dead Universal Analytics property (`UA-4539114-5` in
`app/views/layouts/application.html.erb:97`; UA stopped collecting in July 2023), so logs are
the only analytics. Unique IPs are a proxy for unique users: slightly over-counts (same user,
two networks) and under-counts (shared NAT). Good enough for ranking pages.

**Bots dominate raw traffic.** Of ~880k Rails requests in the week, ~630k were crawler hits on
the blog index and forum permalinks (`Bloggity::BlogPostsController#index` 275k requests from
99k IPs; `Thredded::PostPermalinksController#show` 230k from 176k IPs). Everything below is
filtered to pages, and the "reach" column counts only the **420 IPs that touched a logged-in
memorisation page during the week**, which is the real user base.

### Audience in one table

| Measure | Value |
|---|---|
| Registered users | 45,829 |
| Active in last 30 days (`daily_stats`) | 212 (209 a year ago: flat) |
| Reviewed a verse in last 7 days | 149 users |
| Reviewing IPs per weekday | 75–86 |
| Verse ratings per day (`mark_test_quick`) | 700–2,100 (≈10k/week) |
| Sign-ups last 30 days / last 365 days | 156 / 1,653 |
| 30-day actives who signed up in 2026 | 42 of 212 |
| 30-day actives who signed up 2009–2016 | 127 of 212 |
| Verses per active user | avg 668, max 8,119 |
| Language of actives | English 195, Bahasa Indonesia 16, Afrikaans 1 |
| Translation of actives | NIV 52, ESV 42, KJV 29, NKJV 27, NASB 19, TMB (Indonesian) 17, NNV 13 |
| Country of actives | US 77, Indonesia 15, unknown 94 |
| Reminder email setting of actives | Never 60, Daily 53, Quarterly 34, Annually 33, Weekly 23, Monthly 9 |
| Device on core pages (nginx UA) | desktop 70%, phone 23%, tablet 7% |
| Browser on core pages | Safari 52%, Chrome 37%, Edge 7%, Firefox 4% |
| Mobile API (`/api/v1`) | 3 requests in the week, 7 OAuth tokens in 30 days: effectively unused |
| Forum posts last 90 days / blog posts last 365 days | 1 / 4 |

Two things stand out. The product has a small, loyal, old, desktop-heavy core (most actives
signed up more than a decade ago and carry hundreds of verses). And it has a leaky top of
funnel: ~1,650 sign-ups a year yield a few dozen retained users.

---

## Tiers

Tiers are assigned from measured reach among the 420 active IPs, not from guesswork.

- **T1 – core loop**: reached by more than half of active users in the week.
- **T2 – frequent**: 20–50% reach.
- **T3 – regular**: 5–20% reach.
- **T4 – occasional**: 1–5% reach.
- **T5 – negligible**: under 1%, or zero traffic.
- **Admin**: admin-only.
- **XHR**: JSON/partial endpoints behind a page.

Columns: **Loads** = HTML page loads in 7 days (all IPs). **IPs** = unique IPs making
HTML requests to the action in 7 days (all visitors). **Reach** = unique active-user IPs
(out of 420) that hit the action in any format, HTML or XHR, so it can slightly exceed the
HTML-only IPs column for actions that also serve partials or JSON (dashboard, manage
verses, add verse).

## 1. Logged-in: the core loop

| Path | Controller#action | What it is | Loads | IPs | Reach | Tier | Notes |
|---|---|---|---|---|---|---|---|
| `/`, `/home` | `memverses#home` | Dashboard: due count, verse of the minute, activity feed, devotional, discussions | 1,171 | 236 | 237 | **T1** | Every session starts here. Reminder emails link here. |
| `/test_verse_quick` | `memverses#test_verse_quick` | Review a due verse (the SRS test) | 951 | 213 | 217 | **T1** | "Review" tab. The product. |
| `/mark_test_quick`, `/test_next_verse` | `memverses#*` | Grade and advance | 9,849 + 8,121 | | 211 | XHR | ≈1,400 verse ratings/day. One page load serves ~10 ratings. |
| `/progress` | `memverses#show_progress` | Progress charts (Highcharts, JustGage, Raphael) | 757 | 185 | 195 | **T1** | Third most reached page. Users check progress almost every session. |
| `/upcoming_verses` | `memverses#upcoming_verses` | Upcoming queue partial | 6,775 | 173 | 173 | XHR | Polled from the review page. |
| `/manage_verses` | `memverses#manage_verses` | My verses: list, tag, toggle status, delete, PDF | 665 | 118 | 138 | **T2** | Header button on every page. |
| `/add_verse` | `memverses#add_verse` | Add a verse | 235 | 78 | 83 | **T2** | Header button; reminder email link. `ajax_add` 553 calls / 54 IPs. |
| `/search_verse` | `verses#verse_search` | Search the Bible | 20 HTML, 5,506 `*/*`, 1,651 JSON | | 81 | **T2** | Used as a widget far more than as a page. |
| `/test_ref` | `memverses#test_ref` | Reference recall test | 296 | 74 | 79 | **T2** | `score_ref_test` 2,902 calls / 66 IPs. |
| `/learn` | `memverses#learn` | Learn a new verse | 133 | 53 | 54 | **T3** | Primary tab, yet only 13% reach: learning is a minority of sessions. |
| `/drill_verse` | `memverses#drill_verse` | Practice / drill | 727 | 33 | 33 | **T3** | 33 users, 727 loads: a few heavy users. |
| `/pre_chapter`, `/test_chapter` | `memverses#chapter_explanation`, `#test_chapter` | Chapter review | 83 + 54 | 26 + 18 | 32 | **T3** | |
| `/review`, `/passages/due` | `passages#review`, `#due` | Passage review | 128 | 30 | 30 | **T3** | |
| `/test_accuracy` | `memverses#test_accuracy` | Word-perfect accuracy test | 44 | 22 | 11 | **T4** | |
| `/voice_review` | `memverses#voice_practice` | Voice review | 22 | 14 | ~14 | **T4** | Recently built (`VOICE_PRACTICE_FEATURE.md`). |
| `/memory_verse/:id` | `memverses#show` | Single memverse | 490 | 45 | 41 | **T3** | |
| `/save_progress_report`, `/badge_quests_check`, `/badge_completion_check`, `/load_progress`, `/load_consistency_progress` | | Dashboard/progress XHR | 458–704 each | | 148–167 | XHR | Fired on every dashboard/progress load. |

## 2. Logged-in: profile, progress, community

| Path | Controller#action | What it is | Loads | IPs | Reach | Tier | Notes |
|---|---|---|---|---|---|---|---|
| `/users/:id` | `users#show` | User dashboard / public profile | 11,180 | 2,119 | 71 | **T3** for users | 2,119 IPs is crawler traffic on public profiles; real reach is 17%. |
| `/leaderboard` | `info#leaderboard` | Leaderboard | 693 | 125 | 48 | **T3** | Also public. |
| `/churchboard`, `/groupboard` | `info#*board` | Church / group leaderboards | 97, 85 | 52, 41 | 36, 31 | **T3** | |
| `/countryboard`, `/stateboard`, `/referralboard` | `info#*board` | Other leaderboards | 16, 4, 6 | 6, 4, 6 | ≤6, ≤4, ≤6 | **T4** | Reach is bounded by the all-visitor IPs; at most 1.4%. Fold into one leaderboard page with a filter. |
| `/memverse_clock` | `info#memverse_clock` | "One Church" counter | 26 | 16 | | **T4** | |
| `/update_profile` | `profile#update_profile` | Edit profile and preferences | 64 | 32 | 21 | **T4** | Linked from reminder emails. |
| `/users/edit` | `users/registrations#edit` | Account (email/password) | ~0 | | | **T5** | |
| `/church`, `/church/:id` | `profile#show_church`, `church#show` | My church | 44, 809 | 26, 419 | 10, 15 | **T4** | `church#show` 809 loads is mostly crawl. |
| `/mygroup`, `/groups/:id` | `groups#show` | My group | 144 | 44 | 12 | **T4** | |
| `/referrals/:id` | `profile#referrals` | Referrals | 95 | 28 | | **T4** | |
| `/quick_start` | `home#quick_start` | Quick-start onboarding | 316 | 41 | 39 | **T3** | New-user flow; 41 IPs ≈ the week's sign-ups. |
| `/earned_badges/:id` | `badges#earned_badges` | Badges (JSON) | 97 | | 30 | XHR | Shown on profile. |
| `/quests`, `/quests/:id` | `quests#*` | Quests | 0 | 0 | 0 | **T5** | Only the JSON check fires. |
| `/tweets` | `tweets#index` | Activity feed page | 8 | 8 | | **T5** | Feed is rendered on dashboard anyway. |
| `/news` | `info#news` | News | 14 | 13 | | **T5** | |
| `/country/:id`, `/american_state/:id` | | Country / state pages | 46, 125 | 37, 69 | | **T5** | Crawl traffic. |
| `/chat` | `chat#index` | PubNub chat | 3 | 3 | | **T5** | `debug`, `simple`, `test_keys`, `working` are dev leftovers. |
| `/progression` | `utils#user_progression` | Progression report | 0 | | | **T5** | |

## 3. Logged-in: quiz

| Path | Controller#action | What it is | Loads | IPs | Reach | Tier | Notes |
|---|---|---|---|---|---|---|---|
| `/live_quiz` | `live_quiz#live_quiz` | Live quiz room | 75 | 52 | 15 | **T3** (spiky) | Primary tab; most-edited views in the last year (38 edits). Usage is event-driven. |
| `/quizzes`, `/quizzes/:id` | `quizzes#*` | Quiz list / detail | 0 | | | **T5** | 57 quizzes in DB. |
| `/quiz_questions`, `/submit_question` | `quiz_questions#*` | Question bank | 2, 5 | 1, 5 | | **T5** | 2,551 questions in DB. |
| `/bible_bee_tool`, `/stt_setia` | `info#*` | One-off tools | 3, 3 | | | **T5** | |

## 4. Public pages (no login)

| Path | Controller#action | What it is | Loads | IPs | Tier | Notes |
|---|---|---|---|---|---|---|
| `/` | `home#index` | Landing page | 5,513 | 1,570 | **T1** (public) | 185 active users also pass through it each week (login flow). |
| `/users/sign_in` | `devise/sessions#new` | Login | 3,744 | 2,156 | **T1** (public) | `sessions#create` 752 / 193 IPs: ~27 logins/day. |
| `/users/sign_up` | `registrations#new` | Registration | 328 + 86 | 123 + 41 | **T2** | `registrations#create` 38 + 1 / week. Two form variants (`_form_a`, `_form_b`) are A/B leftovers. |
| `/users/confirmation` | `confirmations#show` | Email confirmation | 191 | 35 | **T3** | |
| `/users/password/*` | `devise/passwords` | Password reset | 38 + 10 | 28 + 9 | **T4** | |
| `/show_vs` | `info#show_vs` | Show a verse (public) | 2,317 | 1,458 | **T3** | SEO/crawl traffic. |
| `/popular` | `info#pop_verses` | Popular verses | 150 | 109 | **T3** | |
| `/demo` | `info#demo_test_verse` | Try-a-verse demo | 90 | 71 | **T3** | Linked twice from landing. |
| `/tutorial` | `info#tutorial` | Text tutorial (en, es) | 81 | 70 | **T3** | 12 active users/week. |
| `/faq` | `info#faq` | FAQ | 67 | 57 | **T3** | Help tab landing. |
| `/contact` | `info#contact` | Contact form | 94 | 70 | **T3** | |
| `/supermemo` | `info#sm_description` | Algorithm explainer | 43 | 40 | **T4** | |
| `/mission` | `info#mission_statement` | Mission | 36 | 33 | **T4** | Footer only. |
| `/volunteer` | `info#volunteer` | Volunteer | 49 | 38 | **T4** | |
| `/verses`, `/verses/:id` | `verses#index`, `#show` | Verse browser | 8 | 8 | **T5** | Public but unlinked. |
| `/read/:tl/:bk/:ch` | `reading#chapter` | Chapter reader | 0 | | **T5** | |
| `/blog`, `/blog/:slug` | Bloggity | Blog | 275k index / 11k show | 99k / 6k | crawl | 62 / 40 active users touch it. 4 posts in a year. |
| `/forum/*` | Thredded | Forum | 230k permalinks / 125k topics | 176k / 104k | crawl | 29 active users touch it. 1 post in 90 days. |
| `/unsubscribe/*email` | `profile#unsubscribe` | Unsubscribe | 11 | 8 | **T4** | |
| `/memverses/memverse_counter` | `memverses#memverse_counter` | Public counter | 2,279 JSON | | XHR | |

## 5. Content pages with zero traffic

`/sermons`, `/pastors`, `/uberverses`, `/translations`, `/verse_scramble`, `/tag_cloud`
(5 loads), `/show_verses_with_tag` (2), `/scribe/*` (1 user, role-gated). Sermons has 0
Active Storage blobs in production.

## 6. Admin (out of redesign scope unless chosen)

`/admin/dashboard` (7 loads/week), `/admin/onboarding_dashboard`, `/admin/quiz_dashboards/*`,
`/admin/quiz_health`, `/admin/sidekiq_health`, `/admin/database` (RailsAdmin), `/sidekiq`,
`/utils_dashboard` and ~45 `utils#*` actions, `/volunteers`, `/quiz_question_approval`,
Thredded moderation, Bloggity management.

## 7. Legacy / dead

- `forem_*` tables (replaced by Thredded); `sessions` table (cookie store now).
- `/chat/debug`, `/chat/simple`, `/chat/test_keys`, `/chat/working`.
- `/voice_practice` → 301; `/forums/...` → 301.
- `info/spritz.html.erb`, `public/spritz_login_success.html`.
- `_form_a` / `_form_b` registration variants; `experiment#finish`.
- `application.mobile.erb`: `mobile_device?` is hard-coded to `false`
  (`app/controllers/application_controller.rb:280`), so it is never served. The single
  `.mobile.erb` view (`info/leaderboard`) is dead too.
- JasmineRails mount; `/api/v1` and Doorkeeper (7 tokens in 30 days).

---

## Summary

| Area | HTML pages | Templates | Weekly reach (of 420 active) |
|---|---|---|---|
| Core loop (dashboard, review, progress, manage, add, search, ref test) | 8 | memverses 30 | 56%, 52%, 46%, 33%, 20%, 19%, 19% |
| Secondary memorisation (learn, drill, chapter, passage, accuracy, voice) | 8 | passages 8 | 3–13% each |
| Profile / leaderboards / groups / church | ~20 | users 9, profile 7, info 28 | 2–17% |
| Onboarding (landing, sign-up, confirm, quick start, tutorial, demo) | 8 | home 2, devise 16 | ~40 new users/week |
| Quiz | 12 | live_quiz 7, quizzes 5, quiz_questions 13 | 4%, event-driven |
| Blog / forum | engines | thredded 6, bloggity 2 | 7–15% of actives, near-zero authoring |
| Content (sermons, pastors, uberverses, games, scribe) | 12 | 17 | 0 |
| Admin | ~60 | admin 8, utils 32 | admin |

**The whole product, as actually used, is about eight pages.** Everything else is either
onboarding (important, low volume), long-tail features a handful of people use, or dead weight.

## Where development effort went (last 12 months, view + stylesheet commits)

```
60 stylesheets   38 live_quiz   24 memverses   20 admin   11 thredded   9 mailers
 9 layouts        9 devise       8 quizzes      6 sermons   6 chat       5 info
```

Live quiz (4% reach) and admin got the most attention; progress (46% reach) and onboarding
got almost none.

## Reproducing the numbers

On fish-eagle (`ssh avitus@192.241.205.154`, the `memverse` alias currently resolves to
martial-eagle via `/etc/hosts`):

```bash
cd /home/avitus/memverse.com/shared/log && zcat -f production.log.7.gz production.log.6.gz production.log.5.gz production.log.4.gz production.log.3.gz production.log.2.gz production.log.1 production.log | awk '/\] Started [A-Z]+ "/{match($0,/\[[0-9a-f-]{36}\]/);id=substr($0,RSTART+1,RLENGTH-2);for(i=1;i<=NF;i++)if($i=="for")ip[id]=$(i+1);next} /\] Processing by /{match($0,/\[[0-9a-f-]{36}\]/);id=substr($0,RSTART+1,RLENGTH-2);for(i=1;i<=NF;i++)if($i=="by"){ca=$(i+1);fmt=$(i+3)};print ca,fmt,ip[id];delete ip[id]}' | awk '$2=="HTML"{n[$1]++;u[$1" "$3]=1} END{for(x in u){split(x,a," ");ips[a[1]]++};for(k in n)printf "%7d %6d %s\n",n[k],ips[k],k}' | sort -rn | head -80
```

Device and browser share come from `shared/log/nginx_access.log*` (root-readable), filtered to
`/test_verse_quick|/learn|/manage_verses|/add_verse|/home|/progress`.
