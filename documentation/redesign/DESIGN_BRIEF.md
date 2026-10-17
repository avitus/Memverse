# Memverse Redesign: Design Brief (draft v0.1)

**Status**: starting point for Andy to edit. Everything in *[brackets]* is a placeholder or
an open question. Numbers come from `PAGE_INVENTORY.md` (7 days of production traffic,
2026-10-10 to 2026-10-17, plus the production database).

---

## 1. Why redesign, and why now

Memverse is a 17-year-old Rails app whose visual shell (fixed-width two-level tab menu,
13px Open Sans, image-button header, "Web Design: Emeka Rajis" footer) predates the
iPhone's dominance. The backend has been modernised through 2025–2026 (Ruby 3.2, Rails 7.2,
Turbo and Stimulus available, Active Storage, Postmark). The front end has not: jQuery
1.12, Sprockets, Raphael, JustGage, Highcharts, a hand-rolled tab menu, no responsive
breakpoints, and a mobile layout that is hard-coded off.

The data says the product is healthy at its core and broken at its edges:

- ~80 people review verses every weekday and rate ~1,400 verses a day. Half of them have
  been members for over a decade and carry hundreds of verses. They are the product.
- ~1,650 people sign up each year and almost none stay (42 of the 212 monthly actives
  joined this year). The onboarding path is where growth is lost.
- 70% of core-page traffic is desktop (Safari 52%, Chrome 37%). This is a desktop product
  used at a desk, and the redesign should make the most of that: wide verse text, keyboard
  flow, dense progress views. Mobile is served by the native apps (iOS, Android/Flutter,
  and the PWA), so the web app only needs to stay usable on a phone, not lead there.
- Nine top-level tabs and 36 sub-tabs expose ~150 pages, of which eight carry the product.

*[Andy: add the personal "why" here: what prompted this, what a successful outcome looks
like to you in one sentence.]*

## 2. Goals and how we will know

| Goal | Metric | Baseline (Oct 2026) | Target |
|---|---|---|---|
| Keep the daily reviewers | Reviewing users per weekday | 75–86 | no drop during or after rollout |
| Retain new sign-ups | 30-day actives who signed up in the last 12 months | ~45 | *[150?]* |
| Keep desktop first-class | Share of core-page loads from desktop | 70% | hold or grow |
| Keep the phone web layout usable | Phone/tablet visitors who complete a rating | *[unmeasured]* | no regression; native apps are the mobile channel |
| Shorten time to first review | Sign-up → first `mark_test_quick` | *[unmeasured]* | same session |
| Reduce surface area | User-facing HTML pages | ~150 | *[~40]* |

Prerequisite: server-side analytics (Ahoy) now record page views and the sign-up, verse
added, verse rated and reference test events (see `documentation/ANALYTICS.md`). The
first deliverable is four weeks of that data, checked against the log-derived numbers
above, plus any instrumentation gaps it reveals, so the baseline column is settled
before anything ships.

## 3. Who it is for

**Persona A: the veteran reviewer (≈ 60% of actives, and the design target).** Signed up
2009–2016, desktop Safari or Chrome, hundreds of verses, often "Never" on reminder emails
because the habit is self-sustaining. Comes in, hits Review, rates 10–30 verses with the keyboard (1–5 keys),
glances at Progress, leaves. Will notice any change to the rating flow and will complain if
it gets slower. Must not be forced through onboarding, and must never get a mobile-style
layout on a 27-inch screen: no giant tap targets, no hidden keyboard shortcuts, no single
narrow column with the verse text squeezed into it.

**Persona B: the new arrival (≈ 40 sign-ups/week, few retained).** Finds the site from
Google or a church recommendation, on a desktop more often than not. A phone arrival
should be pointed at the native app, not asked to memorise verses in a mobile browser. Lands on `/`, maybe tries `/demo`,
signs up, lands on a dashboard with eleven things on it and nine tabs, and does not yet have
a verse to review. Needs: one verse in the queue within sixty seconds, one obvious next
action, and a reason to come back tomorrow.

**Persona C: the Indonesian cohort (≈ 8% of actives).** Bahasa Indonesia interface,
TMB translation. Reminder that i18n (six locales) is live and must survive the redesign.

**Persona D: the group or church leader (small).** Uses church/group leaderboards and
"My Group". Low volume, high loyalty. Keep, but do not design around.

*[Andy: are there school/Bible Bee cohorts worth naming? `/bible_bee_tool` and the quiz
question bank suggest a seasonal audience.]*

## 4. Design principles

1. **The dashboard stays the landing page** (decided 2026-10-17), but it leads with
   today's review: due count and a Start button above everything else, with the
   remaining widgets demoted. Review itself is one click away, never buried.
2. **One primary action per screen.** Rate this verse. Add a verse. Start learning. The
   current pages show six to ten competing links.
3. **Desktop first; mobile belongs to the native apps.** Design every core screen for a
   desktop browser at full width: keyboard rating (1–5, skip), verse text at a comfortable
   measure, progress alongside review. The same pages must still collapse to a readable
   single column on a phone, but no feature is designed around the phone browser. No
   separate mobile site, no phone-shaped layout stretched across a desktop, and a visible
   "get the app" path for phone visitors.
4. **Progress is a reward, not a report.** Users check it almost every session (46% weekly
   reach). It should be glanceable in two seconds and live next to the review flow, not
   behind a tab.
5. **Subtract before adding.** Nine tabs become *[four]*. Zero-traffic pages are removed,
   not restyled.
6. **Do not surprise the veterans.** Vocabulary (Memverse, Learning/Memorized/Pending,
   e-factor, "verses due") and the rating semantics stay exactly as they are.

## 5. Information architecture (proposal)

Current: Home · Learn · Review · Profile · Contact · Leaderboard · Blog · Quiz · Help, each
with 2–7 sub-tabs, plus two image buttons ("Your Verses", "Add More Verses") in the
breadcrumb bar.

Proposed primary navigation (*[edit freely]*):

| Nav item | Contains (today's pages) | Weekly reach today |
|---|---|---|
| **Review** | `test_verse_quick`, `test_ref`, passage/chapter review as modes, `drill_verse`, `test_accuracy`, voice | 52% + 19% + 7% + … |
| **Learn** | `learn`, `add_verse`, `search_verse`, starter pack, popular verses | 13% + 20% + 19% |
| **My Verses** | `manage_verses`, tags, `memory_verse/:id`, PDF export | 33% |
| **Progress** | `show_progress`, badges, quests (as a strip), user dashboard `users/:id` | 46% + 17% |
| **Community** (secondary / "More") | leaderboards (one page, filter by church/group/country), My Group, My Church, live quiz, blog, forum, referrals | 11% + 4% + 15% |
| Account menu (avatar) | profile & preferences, translation, reminders, sign out, help/FAQ, contact | 5% |

What goes away or merges:

- Separate country/state/referral leaderboards → one leaderboard page with a selector.
- `/news`, `/tweets` page, `/memverse_clock`, `/mission` → footer or dashboard widget.
- Quests, badges pages → components on Progress.
- `/sermons`, `/pastors`, `/uberverses`, `/verse_scramble`, `/translations`, `/chat`,
  `/tag_cloud` → retire (zero traffic). *[Andy: confirm each.]*
- Blog and forum: keep engines, restyle only the shell around them, add `noindex` on
  permalinks or a bot challenge; they are 70% of server load for 1 post per quarter.
- Admin and `utils`: untouched in this project.

## 6. Page-by-page scope

| Page | Scope | Why |
|---|---|---|
| Review (`test_verse_quick`) | **Redesign.** Verse-first desktop layout, hint toggle, keyboard rating row, "next due" preview, progress micro-bar beside the verse. Collapses to a phone layout. | 52% reach; the product. |
| Dashboard (`memverses#home`) | **Redesign.** Becomes "today": due count + Start, streak, verse of the day, one community item. Drop the five-tab widget wall. | First screen of every session. |
| Progress (`show_progress`) | **Redesign.** Replace Raphael/JustGage gauges and Highcharts with one modern chart library (Chart.js renders to canvas; hand-written SVG for simple gauges). Fold badges/quests in. | 46% reach; oldest JS on the site. |
| My Verses (`manage_verses`) | **Redesign** as a filterable table/list with inline status toggle. | 33% reach; dense legacy table. |
| Add verse / search | **Redesign** as one flow: type a reference or words → preview → add. Starter pack as a first-run variant. | 20% reach; the onboarding bottleneck. |
| Learn / drill | **Restyle** on the review page's component system. | 13% / 8%. |
| Reference test, passage review, chapter review, accuracy, voice | **Restyle** as Review modes sharing the layout. | 3–19%. |
| Landing `/`, sign-up, login, confirm, quick start, demo | **Redesign** as one onboarding funnel; the demo becomes step one of sign-up. | Growth. |
| Profile / preferences | **Restyle.** Single settings page. | 5%. |
| Leaderboards | **Merge + restyle.** | 11%. |
| Live quiz | **Restyle shell only**; the quiz UI had heavy recent work. | 4%, event-driven. |
| Blog, forum | **Shell only.** | Crawl traffic, no authoring. |
| FAQ, tutorial, contact, mission, volunteer, supermemo | **Restyle** as a help section. | Public, low volume. |
| Email templates (23) | **Restyle** to match. | Reminder emails are the main re-entry path. |

## 7. Visual direction

*[This section is the one most in need of Andy's voice. Options, not decisions.]*

- **Tone**: *[quiet and devotional / warm and encouraging / clean productivity tool]*.
  The existing palette (greens for memorised, muted reds, `#e5e5e7` body, white boxes) is
  documented in `STYLE_GUIDE.md` and is a reasonable base; the problem is layout and
  density, not colour.
- **Typography**: raise base size from 13px to 16px; verse text deserves a readable serif
  *[e.g. Source Serif / Literata]* at 18–20px; UI stays in a sans *[Inter / keep Open Sans]*.
- **Layout**: a real desktop layout, roughly 1100–1200px wide, with verse text at ~72ch and
  a second column for the progress strip, upcoming queue or hints. It collapses to a
  single column under ~768px, enough to read and rate, nothing more. Today's fixed 13px
  shell wastes most of a modern screen.
- **Dark mode**: *[yes/no]*. Cheap if colours are tokens from day one.
- **Logo**: keep *[yes]*; the `logo.png` is 253×31 raster, needs an SVG.
- **Illustration / imagery**: *[none / light line icons only]*.

## 8. Technical constraints and decisions

- Stack stays Rails 7.2 + ERB. Turbo and Stimulus are already in the Gemfile and should
  carry the interactivity; jQuery 1.12 is retired page by page, not big-bang.
- CSS: *[Tailwind via tailwindcss-rails / hand-written tokens + SASS]*. Either way, define
  colour, spacing and type tokens first and rewrite `STYLE_GUIDE.md` to match.
- Charts: one library. *[Chart.js]* replaces Highcharts, Raphael and JustGage.
- Keep `.white-box-bg`-style page container convention or replace it deliberately; many
  views depend on it.
- i18n: all six locales must render; no hard-coded English in new templates.
- Keyboard shortcuts on the review page (1–5, skip) are a contract.
- The old mobile web layout is dead (`mobile_device?` is hard-coded off); remove
  `application.mobile.erb` and that plumbing rather than reviving it. Mobile is the
  native apps' job.
- The API (`/api/v1`, OAuth) is what the iOS app, the Android/Flutter app and the PWA
  client (`documentation/OAUTH_PKCE_DEPLOY_RUNBOOK.md`) run on. It carried little traffic
  in the measured week, but it is the mobile channel: keep it stable and out of the web
  redesign's scope. Nothing in this project may change an API response.
- Tests: Cucumber features cover the core flows and will break on markup changes; budget
  for updating them alongside each page.
- Performance: the review page should render in well under a second on desktop; the
  current page ships ~40 JS files through Sprockets.

## 9. Non-goals

- No new memorisation features during the redesign (no algorithm changes, no new modes).
- No native app work, and no API changes: the apps are a separate track.
- No mobile-web feature work beyond keeping pages readable on a phone.
- No changes to admin, `utils`, RailsAdmin, Sidekiq UI.
- No data model changes beyond what a page needs.

## 10. Phasing (proposal)

1. **Baseline** (4 weeks of data, little effort): validate the Ahoy tracking and bot
   mitigation already in place, fill in the baseline column, add instrumentation only
   where a gap shows up.
2. **Foundation** (2 weeks): tokens, type scale, new layout shell with the new navigation,
   feature-flagged per user (`users.level` or a boolean). Old pages still render inside the
   new shell.
3. **Review + dashboard** (3 weeks): the two T1 pages, designed on desktop and then made
   to collapse. Ship to volunteers first (`/volunteer` list), then to everyone with a
   "switch back" link for a month.
4. **Progress + My Verses + Add** (3 weeks).
5. **Onboarding funnel** (2 weeks): landing, sign-up, demo, starter pack.
6. **Restyle pass** (2 weeks): everything in the Restyle rows; retire the Retire rows.
7. **Remove jQuery, Sprockets cleanup, delete dead views** (1 week).

*[Andy: adjust to your actual availability; this assumes roughly one focused person.]*

## 11. Open questions

1. Is the goal growth (new users) or care (existing users)? The answer changes whether
   phase 5 comes before phase 3. (The desktop-first decision leans toward care.)
2. ~~Should "Review" be the logged-in landing page when verses are due?~~ Decided: the
   dashboard stays, with review first on it (Principle 1).
3. Which of the zero-traffic features are sentimental keeps: sermons, chat, scribe,
   verse scramble, quests?
4. Blog and forum: keep hosting them, or freeze as static and stop paying the crawler tax?
5. Live quiz: is there a scheduled season (Bible Bee?) we must not disrupt?
6. Dark mode, serif verse text, Tailwind or hand-rolled CSS: pick one each.
7. Who else reviews designs before they ship? Volunteers list, a few veteran users?

## 12. References

- `documentation/redesign/PAGE_INVENTORY.md`: every page with measured usage.
- `documentation/STYLE_GUIDE.md`: current palette, type and layout conventions.
- `documentation/MODERNIZATION_PLAN.md` § Frontend Modernization: the technical backlog
  this redesign would close.
- `documentation/VOICE_PRACTICE_FEATURE.md`, `QUIZ_SYSTEM_DOCUMENTATION.md`: recent
  features whose UI should be preserved.
