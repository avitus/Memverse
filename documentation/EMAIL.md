# Email

How Memverse sends mail: the Postmark configuration, the message streams and tags, the
onboarding emails, and the hourly reminder worker. Merged in October 2026 from
`USER_ONBOARDING_EMAIL_FLOW.md`, `POSTMARK_STREAMS_CONFIGURATION.md`,
`REMINDER_EMAIL_ORDERING.md` and `TEMPORARY_EMAIL_DISABLE.md` (all in git history).

## Provider

- Postmark, through the `postmark-rails` gem (Sendgrid was replaced in August 2025).
- `config/environments/production.rb` sets `delivery_method = :postmark` with the API token from
  `ENV['POSTMARK_API_TOKEN']`, falling back to `Rails.application.credentials.dig(:postmark, :api_token)`.
  Production has no local MTA; mail is HTTPS to Postmark and is not tied to the server's IP.
- `UserMailer#add_postmark_unsubscribe_link` (`config/initializers/postmark.rb`) adds
  `List-Unsubscribe` / `List-Unsubscribe-Post` headers pointing at `/unsubscribe/<email>`.

## Message streams and tags

The streams below must exist in the Postmark account with these exact IDs.

| Stream | Purpose | Mailer methods | Tags |
|---|---|---|---|
| `outbound` (Postmark default) | Transactional | `UserMailer#activation`, `UserMailer#onboarding_reminder`, Devise mail (confirmation, password reset) | `account-activation`, `onboarding-reminder` |
| `broadcast` | Bulk | `UserMailer#newsletter_email` | `newsletter` |
| `reminder-stream` | Memorisation reminders | `UserMailer#progression_email_2` … `progression_email_9` | `progression-2` … `progression-9` |
| `forum-stream` | Thredded forum notifications | every `Thredded::BaseMailer` subclass, via the `mail` override in `config/initializers/postmark_streams.rb` | `forum-notification` (unless the mailer sets its own) |

`UserMailer#signup_notification` (tag `signup-notification`, stream `outbound`) still exists but is
no longer called; see the TODO at the end.

## Onboarding flow

1. **Sign-up.** Devise creates the user with `confirmed_at = nil` and sends its confirmation email.
   The separate "signup notification" email was removed in September 2025 (three onboarding
   emails in quick succession triggered Gmail's `450 4.2.1` rate limiting).
2. **Confirmation.** Clicking the link sets `confirmed_at`. `User` has
   `after_update :send_activation_notification, if: :recently_activated?` (`app/models/user.rb`).
3. **Activation email.** `UserMailer#activation` (`app/views/user_mailer/activation.{html,text}.erb`)
   carries the welcome content: login reminder, profile and email-preference steps, first verses.

Two emails per sign-up, spaced by the user's own confirmation click.

### Undeliverable addresses

Postmark rejects suppressed addresses (hard bounce, spam complaint, manual suppression) with
`Postmark::InactiveRecipientError` and malformed ones with `Postmark::InvalidEmailRequestError`.
`User#send_devise_notification` rescues both for every Devise email, logs a warning and records the
notification in `User#undelivered_devise_notification`; `InvalidEmailRequestError` is also reported
to Sentry as a warning, because a misconfigured message raises the same error. The account is still
created, and `Users::RegistrationsController#create` replaces the "confirmation sent" notice with
the `devise.registrations.signed_up_but_email_undeliverable` alert.

## Reminder emails (`SendReminders`)

`app/workers/send_reminders.rb`, a plain `Sidekiq::Worker` on the `high` queue with `retry: false`,
runs **every hour** (`schedule_send_reminders`, cron `0 * * * * UTC` in `config/sidekiq_schedule.yml`).
The reminder emails are **active**: the "TEMPORARY: disable reminder emails" block at the top of
`perform` is commented out and has been since the Postmark migration finished in August 2025.

Each run:

1. Deletes users who never activated: `User.pending.where('created_at < ?', 2.days.ago).delete_all`.
2. Walks all users with `User.in_batches(of: 100)` and iterates each batch with
   `batch.reorder(created_at: :desc)`. `find_each`/`in_batches` ignore a custom order, so the
   newest-first ordering applies **within each batch of 100**; the batches themselves advance by
   primary key.
3. For each user, `update_reminder_freq`, then skips when `reminder_freq == "Never"`, when the run has
   already sent `@throttle = 8` emails (about 192 per day at most), or when `needs_reminder?` is false.
4. Sends the progression email for the user's level and records `last_reminder` with `update_column`
   (no validations or callbacks, so a legacy record that fails a newer validation is still marked):

| `progression` | Email | Who |
|---|---|---|
| 9 | `progression_email_9` | has memorised one or more verses |
| 8 | `progression_email_8` | has completed 3+ sessions |
| 7 | `progression_email_7` | has completed 2 sessions |
| 6 | `progression_email_6` | has completed 1 session |
| 5 | `progression_email_5` | has reviewed at least one verse |
| 4 | `progression_email_4` | has added more than 5 verses |
| 3 | `progression_email_3` | has added 1–5 verses |
| 2 | `progression_email_2` | confirmed account, no verses |
| 1 | none | unconfirmed email |

Addresses that Devise would not accept are logged and skipped rather than sent to Postmark. When
Postmark refuses a recipient (`InactiveRecipientError`, or an `InvalidEmailRequestError` whose message
names the `'To'` field) the attempt still counts as this cycle's reminder, so the address is not retried
every hour; the log line carries only the Postmark error code, never the address.
`InvalidEmailRequestError` is additionally sent to Sentry as a warning (it can also mean the message
itself is malformed). Any other exception is logged and the run continues with the next user.

To change the hourly volume edit `@throttle`; to pause reminders entirely, re-enable the commented
block (or set the schedule entry to `status: disabled`, see [SIDEKIQ.md](./SIDEKIQ.md)).

## Verifying

Run the suites (`bundle exec rspec`, `npm run test:run`, `bundle exec cucumber features`); the mailer
specs assert the stream and tag of every `UserMailer` method and the Thredded override. In
production, `shared/log/sidekiq_worker_*.log` shows one `*** Email reminder: Sent N reminder emails`
line per hourly run.

## TODO

- **Remove the dead signup notification.** `UserMailer#signup_notification`
  (`app/mailers/user_mailer.rb`), `User#send_signup_notification` (`app/models/user.rb`, around line
  1428) and `app/views/user_mailer/signup_notification.{html,text}.erb` are unused since September 2025.
  Delete them together with any specs that reference them, then run the suites.
