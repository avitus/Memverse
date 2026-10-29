# iOS API contract

The app uses the API that is already on `https://www.memverse.com`. It does not require a new OAuth client or a new route.

Responses use the existing envelope. One record is `{ "response": { ... } }`. A page of memverses is `{ "response": [ ... ], "pagination": { "pages": N } }` with 100 records per page. `efactor` may be a JSON string or a number because it is a `BigDecimal`.

## OAuth

The app uses the confidential OAuth application already registered for the previous iOS app. The token request sends that client id and secret as an HTTP Basic header, the same way that app does. The secret is read from `ios/Config/OAuthClient.local.xcconfig` at build time. That file is gitignored and is not in this repository.

1. The app collects the email and password. It does not open the website.
2. `POST /oauth/token` as JSON with `grant_type=password`, `username`, `password`, and `client_id`. The `Authorization` header is `Basic` with the existing client id and secret. No `scope` field. The server's default scope is `public`, which the memverse routes accept.
3. Password-grant tokens do not expire. The app stores the access token and does not refresh it.
4. `POST /oauth/revoke` with `token`, `client_id`, and the same Basic header before the app deletes its Keychain item. A failed revoke leaves the user signed in.

A wrong password is refused and no token is issued.

## Review

`GET /api/v1/memverses?page=N` returns the current user's memverses in canonical order. The app follows `pagination.pages`. A verse is in today's queue when `status` is not `Pending` and `next_test` is on or before the phone's local date. That is the same rule the previous iOS app used. The live API has no separate due-session route.

`GET /api/v1/passages/:id/memverses` is not limited to the current user. The app does not call it.

`GET /api/v1/memverses/:id` and `PUT /api/v1/memverses/:id?q=N` load the record with `current_resource_owner.memverses.find`. Another user's id is a 404.

`PUT` with query `q` from 1 to 5 calls `Memverse#supermemo`. The person picks the grade. The app does not compute `q` from the typed text. The website labels are:

| q | Label |
| --- | --- |
| 1 | Don't Know - No Idea |
| 2 | Don't Know - Familiar |
| 3 | Remembered - Difficult |
| 4 | Remembered - Hesitation |
| 5 | Remembered - Perfect |

`supermemo` is not idempotent. A verse that is not due still increments `attempts` and rewrites `next_test` and `last_tested`. There is no idempotency key. The client sends one `PUT`, then refetches on timeout.

The API update does not record the website's Ahoy `verse_rated` event and does not broadcast or tweet. Those stay on `MemversesController#mark_test_quick`.

Each memverse object is `Memverse#as_json`, including `text`, `tl`, nested `verse`, `feedback`, `mnemonic`, `next_test`, `test_interval`, `rep_n`, `efactor`, and `status`. `as_json` reads `passage.id`. A memverse with no passage raises on serialization. The deployed `as_json` does not include `attempts` or `last_tested`. The decoder treats those as optional.

`feedback` controls whether the practice screen compares the typed text with the verse. `mnemonic` of `""` or `"-"` means the website's first-letter hint is allowed. The comparison does not choose the saved grade.

A due verse graded `5` through `supermemo` moves to interval 4, efactor 2.1, `rep_n` 2, and `next_test` four days ahead. Its `next_test` is then after today, so it leaves the queue.

## Profile

`GET /api/v1/me` returns `serializable_hash` plus `work_load`. That hash includes credential columns. The app decodes `id` and `name` only and does not log the body. This milestone does not change that response.

## Reconciliation

After a transport timeout or a dropped connection, `GET /api/v1/memverses/:id` and compare `rep_n`, `efactor`, `test_interval`, `next_test`, `attempts`, and `last_tested` with the snapshot taken before the `PUT`.

- Unchanged: the grade was not saved. The person may try again.
- Changed: treat it as saved. Do not send another `PUT`.
- The refetch fails: the outcome is ambiguous. Do not send the `PUT` again.
- HTTP 401 on the write: refresh once and retry that `PUT` once. A 401 means the server rejected the call.

## Not used

The app does not add verses, change reference intervals, or call passage, quiz, forum, or blog routes.
