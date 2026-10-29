# Memverse iOS

Native SwiftUI client for one online review session. It lives in this Rails repository under `ios/` and talks to the HTTP API in [API_CONTRACT.md](API_CONTRACT.md). It does not read the database or reimplement scheduling.

Working rules for agents are in `ios/AGENTS.md`.

## Toolchain

- Xcode 26.6, Swift 6.3, iOS Simulator SDK 26.5 (the versions on the machine that produced the first build).
- Language mode in the project: Swift 5. Deployment target: iOS 18. iPhone and iPad.
- Project: `ios/Memverse.xcodeproj`. Shared scheme: `Memverse`. There is no workspace and no Swift package.
- Bundle ID: `com.veetle.Memverse`. Apple team `9UW358LB5Z` is the team that owned the previous listing, and `DEVELOPMENT_TEAM` is set to that team. Simulator builds still sign with the local identity only for the simulator SDK. Marketing version `2.1.0`, build `37`.
- Builds use `xcodebuild`. DerivedData stays outside the repo (`-derivedDataPath /tmp/memverse-ios-dd`).

List simulators with `xcrun simctl list devices available` and pass `platform=iOS Simulator,name=…,OS=…`. Do not commit UUIDs. The destinations used for this milestone are iPhone 17 and iPad Pro 13-inch (M5), both OS 26.5, when those runtimes are installed.

```bash
xcodebuild -project ios/Memverse.xcodeproj -scheme Memverse \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/memverse-ios-dd -configuration Debug build

xcodebuild -project ios/Memverse.xcodeproj -scheme Memverse \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/memverse-ios-dd -configuration Debug test
```

Use the same test command with the iPad destination. Run one test action at a time.

## Configuration

| Build | API base | ATS |
| --- | --- | --- |
| Debug | `MEMVERSE_API_BASE_URL`, or `http://127.0.0.1:3000` | `ios/Config/Info-Debug.plist` allows insecure HTTP for `localhost` (including subdomains) and `127.0.0.1` only |
| Release | `https://www.memverse.com` | `ios/Config/Info.plist` has no exception |

Debug must not target production. Release talks to `https://www.memverse.com` and signs in with the OAuth application the previous iOS app already uses. No new client and no new route are required.

Local development, after MySQL and Redis are up:

```bash
bundle exec rails server
```

A debug build can sign in only when that same OAuth application exists in the local database. Use a synthetic user. Do not use a personal account, production data, or `config/master.key` for client tests.

UI tests do not log in. `-uiTestingSignedOut` stays on the sign-in screen. `-uiTestingQueue` shows one synthetic verse, reference `Fixture 1:1`, text `Alpha bravo charlie.` `-uiTestingLoadFailed` shows the signed-in load error and does not call the network.

## Identity and release

This client is an update of the existing app record, not a new listing. The bundle ID stays `com.veetle.Memverse`. The same Apple team keeps the record, ratings, and URL. Removing the app record would permanently spend the bundle ID if a build was uploaded. Do not click Remove App. The `com.veetle` prefix is a bundle-ID prefix, not an Apple organization that has to be recreated.

The app signs in with the previous iOS app's OAuth client: email and password posted to `/oauth/token`, with that client's existing Basic credentials. Those tokens do not expire.

- On 2026-10-21, Release `2.1.0` (39) was uploaded. Delivery UUID `993fdb66-5506-41cd-85e2-e45bdb2eeab6`. It signs in with the previous iOS app's OAuth client and loads due verses from `GET /api/v1/memverses`. Build 38 still names itself `memverse-ios`. After an iOS change, upload the next TestFlight build. Do not submit for App Store review unless the user asks.

## CI

CircleCI stays the existing Linux Docker `build` job (RSpec, then Vitest on node 0, then Cucumber). A macOS `xcodebuild` job is not enabled. It would be a paid executor and needs an explicit approval. Do not add path filters that skip the Rails checks. Until that job exists, iOS builds run on a Mac with Xcode installed.

## What the first session does

Sign in by posting the email and password to `POST /oauth/token` with the existing iOS client. The app does not open the website. Load `GET /api/v1/memverses`, page by page, and keep verses whose status is not Pending and whose `next_test` is on or before the phone's local date. Practice one verse: reference and translation visible, the server's first-letter mnemonic when it is not blank or `"-"`, verse text hidden until "Show verse", typed comparison as a hint, then a self-grade from 1 to 5. `PUT /api/v1/memverses/:id?q=N` calls `Memverse#supermemo`. The hint does not pick the grade. After a save, the next remaining due verse opens and the saved note stays until a different verse is chosen. When the queue is empty, the saved note stays on screen. A failed load keeps the sign-in session and offers Try again. Sign-out from the queue asks first.

One submission is in flight at a time. A timeout refetches the memverse and compares `rep_n`, `efactor`, `test_interval`, `next_test`, `attempts`, and `last_tested`. An unchanged record can be retried. A changed record is saved and is not sent again. A failed refetch stays ambiguous and is not replayed. Logout revokes first.

iPhone uses the compact column of `NavigationSplitView`. iPad shows the list and the detail together when the width allows it. System text styles follow Dynamic Type. The hidden verse is absent from the accessibility tree until it is shown. The hint's accessibility label says whether the answer matches, and it does not speak the verse.

## Offline milestone (not built)

Online practice is the first milestone. A later offline milestone needs a bounded download for one account and a durable outbox. Client UUIDs do not deduplicate server effects. `supermemo` has no idempotency key, and a repeat `PUT` changes `attempts` even when the verse is no longer due.

Before implementing sync, the server needs an account-scoped deduplication key and one transaction that applies the grade and records that key. The client should store pending events with a stable id, the account id, the memverse id, `q`, and the time the person graded. Receipt time and the device clock do not replace the server's review date. Logout or an account switch must not upload another account's outbox. Pending work stays on device until the server accepts it or the person discards it explicitly. The UI has to show local, syncing, synced, failed, and conflicted states. Cached verse text needs a rights check before it is stored for offline use. Website access is not a license to redistribute a translation.

Do not start that work by adding a local database to this milestone.

## Verification

- Debug build of scheme `Memverse` for iPhone 17, OS 26.5, succeeded. DerivedData was `/tmp/memverse-ios-dd`. The built Info.plist allows insecure HTTP only for `localhost` and `127.0.0.1`.
- Release build for the same destination succeeded. Its Info.plist has the `memverse` URL scheme and no `NSAppTransportSecurity` key. Bundle ID is `com.veetle.Memverse`.
- Unit tests (17) and the fixture UI tests (signed out, load failure, review and save, largest Dynamic Type) passed on iPhone 17, OS 26.5 (`/tmp/memverse-ios-dd/Logs/Test/Test-Memverse-2026.10.21_14-32-52--0700.xcresult`) and on iPad Pro 13-inch (M5), OS 26.5 (`/tmp/memverse-ios-dd-ipad/Logs/Test/Test-Memverse-2026.10.21_14-33-31--0700.xcresult`). The live sign-in test stays skipped unless `LiveCredentials` is filled.
- A second pass with the simulator content size set to `accessibility-extra-extra-extra-large` passed on both devices. On iPhone the grade buttons sit below the first screen and the practice view scrolls. On iPad the list and the practice pane stay side by side, and long grade labels wrap.
- iPhone signed-out and practice UI tests also passed with the simulator appearance set to dark. The appearance was set back to light afterward.
- This client change does not modify the server. Sign-in uses the OAuth application the previous iOS app already registered, and the queue comes from `GET /api/v1/memverses`.
- An earlier iPhone 17 run, on 2026-10-20, signed in through the website session and saved grade 5 for the synthetic development account. That path is gone. This change was not repeated as a live sign-in: `LiveCredentials` stays nil, and the password is not in the repo.
- VoiceOver was not run. The hidden verse is absent until "Show verse", and the hint's accessibility label does not speak the verse text. A narrowed iPad window was not resized. Reduce Motion has nothing custom to disable.
