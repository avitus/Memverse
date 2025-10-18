# Live Quiz Auto-Refresh Test Plan

## Overview

This document outlines the comprehensive test plan for the live quiz auto-refresh feature. The feature ensures users automatically transition from the quiz schedule page to the active quiz interface when the quiz worker starts.

## Architecture

### Recent Changes (October 2025)

1. **Conflict Resolution**: jQuery countdown now detects and defers to Stimulus controller when quiz is preparing
2. **Shared SessionStorage Flag**: Both systems use `quiz_reload_scheduled` to coordinate reload attempts
3. **Increased Delay**: Changed from 2 to 3 seconds for more reliable worker status updates
4. **Enhanced Status Detection**: Controller now recognizes multiple "preparing" status values

### Components Tested

1. **JavaScript Countdown Timer** (`app/assets/javascripts/live_quiz.js`)
   - Monitors countdown to quiz start time
   - Triggers page refresh when countdown reaches zero
   - Uses sessionStorage to prevent duplicate reloads

2. **Stimulus Controller** (`app/javascript/controllers/live_quiz_controller.js`)
   - Polls `/live_quiz/till_start` endpoint every 2 seconds when quiz is preparing
   - Detects status change from "Initializing" to "Wait for question"
   - Triggers page refresh when quiz is ready

3. **Quiz Worker** (`app/workers/knowledge_quiz.rb`)
   - Updates Redis status from "Initializing" to "Wait for question"
   - Manages quiz execution lifecycle

4. **QuizSession Service** (`app/services/quiz_session.rb`)
   - Manages Redis quiz state
   - Provides status checking methods
   - Handles participant tracking

## Test Files

### 1. Unit Tests - JavaScript Countdown Logic

**File:** `test/javascript/live_quiz_countdown.test.js`

#### Test Coverage

- **Countdown Initialization**
  - ✓ Initializes when quiz schedule element is present
  - ✓ Does not initialize when element is missing
  - ✓ Clears existing interval before creating new one
  - ✓ Resets reloadScheduled flag on init

- **Countdown Display Logic**
  - ✓ Displays days, hours, minutes for distant countdowns
  - ✓ Displays seconds when < 1 minute remains
  - ✓ Shows "Preparing quiz..." within 20 seconds
  - ✓ Shows "Loading quiz..." when countdown expires

- **Auto-Refresh Trigger**
  - ✓ Schedules reload when countdown reaches zero
  - ✓ Sets sessionStorage flag before reload
  - ✓ Clears sessionStorage and reloads after 3-second delay
  - ✓ Prevents multiple reloads for same countdown
  - ✓ Clears interval when scheduling reload

- **Interval Management**
  - ✓ Starts with 5-second update interval
  - ✓ Switches to 1-second interval when < 60 seconds remain
  - ✓ Only switches to fast interval once

- **Edge Cases**
  - ✓ Handles missing countdown element gracefully
  - ✓ Does not update after reload is scheduled
  - ✓ Handles invalid target time

**Run Command:**
```bash
npm test test/javascript/live_quiz_countdown.test.js
```

### 2. Integration Tests - Quiz State Transitions

**File:** `test/javascript/live_quiz_state_transitions.test.js`

#### Test Coverage

- **Quiz State: Preparing → Ready**
  - ✓ Starts polling when quizPreparingValue is true
  - ✓ Does not start polling when quizPreparingValue is false
  - ✓ Checks quiz status immediately on connect
  - ✓ Polls every 2 seconds

- **Status Detection and Page Refresh**
  - ✓ Detects "Wait for question" status
  - ✓ Refreshes page when quiz is ready (with Turbo)
  - ✓ Refreshes page when quiz is ready (without Turbo)
  - ✓ Continues polling when status is "Initializing"
  - ✓ Stops polling after successful refresh

- **Error Handling**
  - ✓ Handles fetch errors gracefully
  - ✓ Handles non-OK HTTP responses
  - ✓ Handles malformed JSON responses
  - ✓ Continues polling despite errors

- **Cleanup on Disconnect**
  - ✓ Clears interval when controller disconnects
  - ✓ Does not error when disconnecting without active interval

- **Multiple State Transitions**
  - ✓ Handles rapid status changes
  - ✓ Prevents multiple refreshes

- **Quiz Worker Status Values**
  - ✓ Tests all possible status values
  - ✓ Validates "Wait for question" triggers refresh
  - ✓ Validates "Initializing" continues polling

**Run Command:**
```bash
npm test test/javascript/live_quiz_state_transitions.test.js
```

### 3. End-to-End Tests - Full User Scenarios

**File:** `spec/features/live_quiz_auto_refresh_spec.rb`

#### Test Coverage

- **Quiz Schedule Page Countdown**
  - ✓ Displays countdown timer on schedule page
  - ✓ Shows time until quiz starts
  - ✓ Displays "Loading quiz..." when countdown expires
  - ✓ Displays "Preparing quiz..." within 20 seconds

- **Quiz Worker Status Transitions**
  - ✓ Displays preparing overlay when status is "Initializing"
  - ✓ Polls till_start endpoint for status
  - ✓ Displays quiz interface when status is "Wait for question"
  - ✓ Shows question dots

- **till_start Endpoint Polling**
  - ✓ Returns initializing status during preparation
  - ✓ Returns ready status when quiz is active
  - ✓ Returns time until start for scheduled quizzes

- **Multiple Users Joining Simultaneously**
  - ✓ All users can access quiz interface
  - ✓ Participants are tracked in Redis
  - ✓ No race conditions in participant tracking

- **SessionStorage Behavior Across Tabs**
  - ✓ Sets sessionStorage flag to prevent multiple reloads
  - ✓ Shows preparing overlay immediately when already preparing

- **Slow Network Conditions**
  - ✓ Continues polling after delayed response
  - ✓ Handles 500 errors gracefully

- **Race Conditions**
  - ✓ Shows correct state when status changes during page load
  - ✓ Redis lock prevents duplicate worker execution

- **Browser Tab Switching**
  - ✓ Countdown continues in background
  - ✓ Shows current quiz state when user returns

- **Page Refresh Mechanics**
  - ✓ Polling detects status change
  - ✓ Uses Turbo.visit when available
  - ✓ Falls back to window.location.reload

- **Edge Cases**
  - ✓ Handles missing quiz gracefully
  - ✓ Handles corrupted Redis data
  - ✓ Handles concurrent status updates

**Run Command:**
```bash
bundle exec rspec spec/features/live_quiz_auto_refresh_spec.rb
```

## Test Scenarios

### Scenario 1: User Visits Before Quiz Starts

**Given:** Quiz is scheduled for 5 minutes in the future
**When:** User visits `/live_quiz`
**Then:**
1. Page displays quiz schedule with countdown timer
2. Countdown shows "5m" and counts down
3. When countdown reaches 20 seconds, shows "Preparing quiz..."
4. When countdown reaches 0, shows "Loading quiz..."
5. After 3-second delay, page refreshes automatically
6. sessionStorage prevents duplicate reloads

**Tests:** `live_quiz_countdown.test.js`, `live_quiz_auto_refresh_spec.rb`

### Scenario 2: User Visits During Quiz Preparation

**Given:** Quiz worker has started and set status to "Initializing"
**When:** User visits `/live_quiz?quiz=1`
**Then:**
1. Page displays preparing overlay
2. Stimulus controller starts polling every 2 seconds
3. Controller calls `/live_quiz/till_start?id=1`
4. Receives status: "In progress. Initializing..."
5. Continues polling
6. Worker updates status to "Wait for question"
7. Next poll receives ready status
8. Page refreshes automatically
9. After refresh, quiz interface loads

**Tests:** `live_quiz_state_transitions.test.js`, `live_quiz_auto_refresh_spec.rb`

### Scenario 3: User Visits After Quiz is Ready

**Given:** Quiz worker has completed initialization
**When:** User visits `/live_quiz?quiz=1`
**Then:**
1. Page checks Redis status
2. Finds status: "In progress. Wait for question."
3. Sets `quiz_preparing` to false
4. Renders quiz interface immediately
5. No polling occurs
6. User can participate in quiz

**Tests:** `live_quiz_auto_refresh_spec.rb`

### Scenario 4: Multiple Users Join Simultaneously

**Given:** Quiz worker changes status to "Wait for question"
**When:** 50 users visit page within same second
**Then:**
1. All users poll `/live_quiz/till_start` at similar times
2. All receive "Wait for question" status
3. All pages refresh automatically
4. All users load quiz interface successfully
5. Redis correctly tracks all participants
6. No duplicate participant entries

**Tests:** `live_quiz_auto_refresh_spec.rb`

### Scenario 5: User Opens Multiple Tabs

**Given:** User has quiz page open in 3 tabs
**When:** Countdown reaches zero in all tabs
**Then:**
1. First tab sets sessionStorage flag
2. First tab schedules reload
3. Second tab checks sessionStorage, finds flag
4. Second tab displays "Loading quiz..." but doesn't reload
5. Third tab behaves same as second tab
6. Only one reload occurs per browser
7. After reload, all tabs show quiz interface

**Tests:** `live_quiz_countdown.test.js`, `live_quiz_auto_refresh_spec.rb`

### Scenario 6: Network Request Fails

**Given:** Quiz is preparing and polling is active
**When:** `/live_quiz/till_start` request fails with network error
**Then:**
1. JavaScript catch block logs error
2. Polling interval continues
3. Next poll attempt occurs after 2 seconds
4. If successful, normal flow resumes
5. User sees quiz when it becomes ready

**Tests:** `live_quiz_state_transitions.test.js`, `live_quiz_auto_refresh_spec.rb`

### Scenario 7: User Switches Browser Tabs

**Given:** User is on quiz schedule page with 2-minute countdown
**When:** User switches to different tab
**Then:**
1. JavaScript setInterval continues running
2. Countdown continues in background
3. When countdown reaches zero, page refreshes
4. User returns to tab and sees quiz interface

**Tests:** `live_quiz_countdown.test.js`, `live_quiz_auto_refresh_spec.rb`

### Scenario 8: Quiz Worker Crashes During Initialization

**Given:** Worker starts but crashes before setting "Wait for question"
**When:** User is polling for status
**Then:**
1. User continues polling
2. Receives "Initializing" status repeatedly
3. After timeout (if implemented), shows error
4. Or continues until worker is restarted
5. User can manually refresh to check status

**Tests:** `live_quiz_state_transitions.test.js`

## Running All Tests

### Run All JavaScript Tests
```bash
npm test
```

### Run All RSpec Tests
```bash
bundle exec rspec
```

### Run Only Live Quiz Tests
```bash
# JavaScript
npm test -- test/javascript/live_quiz_countdown.test.js
npm test -- test/javascript/live_quiz_state_transitions.test.js

# RSpec
bundle exec rspec spec/features/live_quiz_auto_refresh_spec.rb
bundle exec rspec spec/features/live_quiz_spec.rb
bundle exec rspec spec/controllers/live_quiz_controller_spec.rb
```

### Run with Coverage
```bash
# JavaScript coverage
npm run test:coverage

# RSpec coverage
COVERAGE=true bundle exec rspec
```

## Continuous Integration

These tests should be run in CI/CD pipeline:

1. **Pre-commit:** Run JavaScript unit tests
2. **Pull Request:** Run all tests
3. **Pre-deployment:** Run all tests + manual smoke test

## Manual Testing Checklist

After automated tests pass, perform manual verification:

- [ ] Open `/live_quiz` in browser
- [ ] Verify countdown displays correctly
- [ ] Open developer console, monitor network requests
- [ ] Verify sessionStorage flags are set/cleared
- [ ] Open multiple tabs, verify only one reloads
- [ ] Throttle network to "Slow 3G", verify polling continues
- [ ] Start quiz worker, verify status polling works
- [ ] Verify page refreshes when worker completes initialization
- [ ] Join quiz with multiple users, verify all can participate

## Troubleshooting

### Tests Failing Due to Timing Issues

If tests fail intermittently due to timing:

1. Check if `vi.useFakeTimers()` is properly configured
2. Ensure `await vi.runOnlyPendingTimersAsync()` is called after async operations
3. Increase timeout for slow CI environments

### Tests Failing Due to Redis

If Redis-related tests fail:

1. Ensure Redis is running: `redis-cli ping`
2. Clear Redis before tests: `redis-cli FLUSHDB`
3. Check Redis connection in `config/initializers/redis.rb`

### Tests Failing Due to Missing Dependencies

1. Install JavaScript dependencies: `npm install`
2. Install Ruby gems: `bundle install`
3. Run database migrations: `bundle exec rake db:test:prepare`

## Performance Considerations

### Polling Frequency

- **Initial polling:** Every 2 seconds
- **Rationale:** Balance between responsiveness and server load
- **Trade-off:** 3-second max delay for users to see quiz (increased for reliability)

### Countdown Update Frequency

- **Normal:** Every 5 seconds
- **Final minute:** Every 1 second
- **Rationale:** More frequent updates as quiz approaches

### SessionStorage Usage

- **Purpose:** Prevent duplicate reloads across tabs
- **Cleanup:** Removed after reload to prevent stale flags
- **Expiry:** No TTL needed (cleared on reload)

## Future Improvements

1. **WebSocket Support:** Replace polling with WebSocket push notifications
2. **Service Worker:** Cache quiz interface for faster loads
3. **Progressive Enhancement:** Fallback for browsers without JavaScript
4. **Loading States:** Show spinner during status checks
5. **Error Recovery:** Retry logic for failed network requests
6. **Analytics:** Track how many users hit each code path

## Related Documentation

- [Live Quiz Countdown Fix](./LIVE_QUIZ_COUNTDOWN_FIX.md)
- [Style Guide](./STYLE_GUIDE.md)
- [Modernization Plan](./MODERNIZATION_PLAN.md)
