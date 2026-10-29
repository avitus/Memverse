# iOS agent instructions

Native Memverse client. Repository-wide safety, secrets, and git rules stay in the root `AGENTS.md`. Setup, decisions, and verification status are in `documentation/ios/README.md`. The HTTP contract is `documentation/ios/API_CONTRACT.md`.

## Project

- Working directory: repository root.
- Project: `ios/Memverse.xcodeproj` (no workspace).
- Shared scheme: `Memverse`.
- App sources: `ios/Memverse/`.
- Unit tests: `ios/MemverseTests/` (Swift Testing).
- UI tests: `ios/MemverseUITests/` (XCTest). Debug-only launch arguments `-uiTestingSignedOut` and `-uiTestingQueue` supply a synthetic fixture and do not call the network. `-uiTestingLoadFailed` shows the signed-in load error. `-uiTestingResetKeychain` clears the Keychain before launch. `LiveReviewUITests` signs in against a local Rails server only when `LiveCredentials` is filled; leave those values nil.
- Bundle ID: `com.veetle.Memverse`. This is the existing App Store record. Do not register it under a different Apple ID, and do not remove the app record.
- `DEVELOPMENT_TEAM` is `9UW358LB5Z`. Simulator signing stays limited to the simulator SDK. Do not disable device signing globally. After an iOS change, archive Release and upload the next build to TestFlight. Do not submit for App Review unless the user asks.
- Deployment target: iOS 18. Swift language mode: 5. Device families: iPhone and iPad.

## Destinations

List simulators with `xcrun simctl list devices available`. Do not commit simulator UUIDs. Prefer a name and OS:

- `platform=iOS Simulator,name=iPhone 17,OS=26.5`
- `platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.5`

Put DerivedData outside the tree, for example `-derivedDataPath /tmp/memverse-ios-dd`.

## Commands

Build:

```bash
xcodebuild -project ios/Memverse.xcodeproj -scheme Memverse \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/memverse-ios-dd -configuration Debug build
```

Test (unit and UI):

```bash
xcodebuild -project ios/Memverse.xcodeproj -scheme Memverse \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath /tmp/memverse-ios-dd -configuration Debug test
```

Repeat the test command for the iPad destination. One `xcodebuild test` at a time against these simulators.

Debug talks to `http://127.0.0.1:3000` unless `MEMVERSE_API_BASE_URL` is set. Release talks only to `https://www.memverse.com`. The local HTTP exception is in `ios/Config/Info-Debug.plist` and covers `localhost` and `127.0.0.1` only. `ios/Config/Info.plist` has no ATS exception.

Xcode MCP is not part of this checkout. Use `xcodebuild` and `simctl`. Do not point a debug build at production, and do not create the production OAuth client.

## Swift conventions

- SwiftUI and the system frameworks already linked by the app target. Do not add a package manager or a third-party dependency for this client.
- Keep scheduling on the server. The grade a person picks is sent as `q`. Text comparison is presentation only.
- Tokens live in the Keychain (`com.veetle.Memverse.oauth`). Do not store them in UserDefaults or log them.
- Decode `GET /api/v1/me` for `id` and `name` only. Do not log that response body.
- One grade submission at a time. A timeout is ambiguous: refetch and compare the scheduling snapshot. Do not automatically send the same `PUT` again.
- Logout clears the Keychain only after revoke succeeds.

## Completion

A Swift-only change needs a successful simulator build and the affected client tests. An API, authentication, or review-behavior change also needs the Rails sequence in root `AGENTS.md` (RSpec, then Vitest, then Cucumber) and a safe-backend check when one can run. Do not commit, push, deploy, or upload a build unless the user asks.
