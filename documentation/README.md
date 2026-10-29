# Memverse documentation

One line per document. Root-level guides: [`../CLAUDE.md`](../CLAUDE.md) (project guide, architecture,
production summary) and [`../AGENTS.md`](../AGENTS.md) (rules for coding agents). Anything not listed
here was merged into one of these pages in October 2026 and is still available in git history.

## Operations

| Document | Purpose |
|---|---|
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Capistrano deploys to martial-eagle: host facts, what a deploy does, credentials, rollback |
| [SIDEKIQ.md](./SIDEKIQ.md) | Background jobs: scheduler/worker split, every worker, the 8 cron entries and the rules for editing them, systemd units, monitoring |
| [EMAIL.md](./EMAIL.md) | Postmark streams and tags, onboarding emails, the hourly reminder worker, the signup-notification TODO |
| [ERROR_MONITORING.md](./ERROR_MONITORING.md) | Sentry 6.7 configuration, release detection from Capistrano, email scrubbing |
| [ATTACK_PROTECTION.md](./ATTACK_PROTECTION.md) | `AttackProtectionMiddleware` (blocked paths, attack tools, scraper bots, IP spoofing) and the rack-attack backstop |
| [ANALYTICS.md](./ANALYTICS.md) | Server-side analytics with Ahoy and bot mitigation |

## Subsystems

| Document | Purpose |
|---|---|
| [API.md](./API.md) | API v1: Doorkeeper OAuth (PKCE, legacy password grant), endpoint list, response envelope, Swagger, follow-ups |
| [QUIZ_SYSTEM.md](./QUIZ_SYSTEM.md) | Live knowledge quiz and custom quizzes: data model, worker timeline, Redis keys, browser refresh coordination, admin tools |
| [FEEDBACK_VOTING_SETUP.md](./FEEDBACK_VOTING_SETUP.md) | Thredded feedback board with voting: setup, implementation files, welcome topic |
| [VOICE_PRACTICE_FEATURE.md](./VOICE_PRACTICE_FEATURE.md) | Voice review page (`/voice_review`): Web Speech API, word-level comparison, tests |
| [STYLE_GUIDE.md](./STYLE_GUIDE.md) | Visual design standards and CSS conventions |

## Roadmap, plans and specs

| Document | Purpose |
|---|---|
| [MODERNIZATION_PLAN.md](./MODERNIZATION_PLAN.md) | What has been modernized and what remains (Dockerfile, Sidekiq 8, CSP, jQuery, search) |
| [plans/2026-06-26-rails-7.2-upgrade.md](./plans/2026-06-26-rails-7.2-upgrade.md) | Rails 7.1 → 7.2 implementation plan (completed) |
| [specs/2026-06-26-rails-7.2-upgrade-design.md](./specs/2026-06-26-rails-7.2-upgrade-design.md) | Design spec for the Rails 7.2 upgrade (completed) |
| [plans/2026-08-11-sentry-release-tracking.md](./plans/2026-08-11-sentry-release-tracking.md) | sentry-raven → sentry-ruby migration plan (completed) |
| [specs/2026-08-11-sentry-release-tracking-design.md](./specs/2026-08-11-sentry-release-tracking-design.md) | Design spec for Sentry release tracking (completed) |
| [plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md](./plans/2026-10-10-fish-eagle-to-martial-eagle-migration.md) | Production host migration runbook, executed 2026-10-17; open items (backup restore proof, andyvitus.com, fish-eagle decommission) at the top |
| [specs/2025-08-quiz-url-structure-proposal.md](./specs/2025-08-quiz-url-structure-proposal.md) | Proposal to unify quiz URLs (not adopted) |
| [specs/voice-review-comparison-prd.md](./specs/voice-review-comparison-prd.md) | Original PRD for voice comparison (superseded by VOICE_PRACTICE_FEATURE.md) |

## Redesign

| Document | Purpose |
|---|---|
| [redesign/DESIGN_BRIEF.md](./redesign/DESIGN_BRIEF.md) | Draft design brief for the site redesign |
| [redesign/PAGE_INVENTORY.md](./redesign/PAGE_INVENTORY.md) | Page-by-page traffic inventory from a week of production logs (October 2026) |

## Conventions

- All documentation lives in this directory; add new pages here and list them above.
- Do not record test counts in docs; say "run the suites" (`bundle exec rspec`, `npm run test:run`,
  `bundle exec cucumber features`).
- Incident write-ups belong in the relevant subsystem page as a short "history" note, not as a new file.
