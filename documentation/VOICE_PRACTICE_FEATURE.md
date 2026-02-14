# Voice Practice Feature Documentation

## Overview

Voice Practice is a feature that allows users to practice Bible verse memorization by speaking verses aloud. The browser's Web Speech API captures spoken words in real-time, compares them against the actual verse text, and provides visual feedback on accuracy.

**URL:** `/voice_review` (canonical) or `/voice_practice` (redirects to `/voice_review`)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Browser                                  │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │  Web Speech API │───▶│ Voice Comparison│───▶│   Display    │ │
│  │  (recognition)  │    │   Algorithm     │    │  (DOM/CSS)   │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│           │                                            │         │
│           ▼                                            ▼         │
│  ┌─────────────────┐                          ┌──────────────┐  │
│  │ Interim/Final   │                          │ Rating Submit│  │
│  │ Transcription   │                          │   (AJAX)     │  │
│  └─────────────────┘                          └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                                        │
                                                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Server                                   │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │ MemversesController│  │  Passage Model  │    │ Memverse     │ │
│  │ #voice_practice │───▶│  .due.active    │───▶│ Model        │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## File Structure

| File | Purpose |
|------|---------|
| `app/views/memverses/voice_practice.html.erb` | Main view with HTML structure and inline JavaScript |
| `app/assets/stylesheets/mv_voice_practice.scss` | All CSS styles for the voice practice page |
| `app/javascript/voice_comparison.js` | Reusable ES6 module with comparison algorithms (for testing) |
| `test/javascript/voice_comparison.test.js` | Vitest test suite (153+ tests) |
| `app/controllers/memverses_controller.rb` | Controller action `#voice_practice` |
| `config/routes.rb` | Route definitions |
| `spec/controllers/memverses_controller_spec.rb` | Controller specs |

## Components

### 1. Controller Action

**Location:** `app/controllers/memverses_controller.rb:1326`

```ruby
def voice_practice
  @tab = "learn"
  @sub = "voice"

  # Check if user has any verses
  unless current_user.memverses.active.exists?
    flash[:notice] = "You need to add some verses first."
    redirect_to add_verse_path and return
  end

  # Get passages due for review
  passage = current_user.passages.due.active.first

  if passage
    @mv = passage.memverses.active.includes(:verse).order('verses.versenum').first
  end

  unless @mv
    flash[:notice] = "You have completed your review for today!"
    redirect_to progress_path and return
  end
end
```

### 2. Voice Review State Manager

**Location:** `app/views/memverses/voice_practice.html.erb` (inline JavaScript)

The `voiceReviewState` object manages the client-side state for passage navigation:

```javascript
var voiceReviewState = {
  passages: [],           // List of due passages
  currentPassageId: null, // Current passage being reviewed
  currentPassageRef: null,
  passageVerses: [],      // All memverses in current passage
  currentVerseIndex: -1,  // Index of current verse being reviewed
  currentVerse: null,     // Current verse data

  // Methods
  initialize(),           // Fetch due passages and start
  selectPassage(),        // Load a passage by ID
  gotoFirstDueVerse(),    // Find first due verse in passage
  displayVerse(),         // Update DOM with verse data
  gotoNextVerseDue(),     // Navigate to next due verse
  markCurrentVerseReviewed(), // Update local state after rating
  clearCurrentPassage(),  // Reset state when passage complete
  autoAdvancePassage()    // Move to next passage
};
```

**Key API Endpoints Used:**
- `GET /passages/due.json` - List of due passages
- `GET /passages/:id/memverses.json` - Verses in a passage
- `GET /mark_test_quick?mv=:id&q=:rating` - Submit rating

### 3. Comparison Algorithm

**Location:** `app/views/memverses/voice_practice.html.erb` (inline) and `app/javascript/voice_comparison.js` (module)

The comparison uses a **Suffix LCS (Longest Common Subsequence)** algorithm for optimal word alignment:

#### Algorithm: `greedyAlign(spokenWords, actualWords)`

1. **Build Suffix LCS Table:** `suffixLcs[i][j]` = LCS length of `spoken[i:]` and `actual[j:]`
2. **Forward Alignment:** Walk through both arrays, using suffix LCS to decide optimal alignment
3. **Match/Skip Decision:** At each position, compare future LCS values to decide whether to:
   - Mark words as matching (both arrays advance)
   - Mark spoken word as "extra" (spoken array advances)
   - Mark actual word as "missing" (actual array advances)
4. **Tie-breaking:** When future LCS values are equal, prefer marking spoken as extra (user made mistake)

**Why Suffix LCS?**
- Prevents cascading errors when first word is wrong
- Handles repeated phrases correctly (prefers earlier matches)
- Optimal global alignment without greedy local decisions

#### Word Statuses

| Status | Meaning | Visual |
|--------|---------|--------|
| `correct` | Word matches expected | Normal text |
| `wrong` | Substitution (said different word) | Red strikethrough + green expected |
| `missing` | Word was skipped | Green underline |
| `extra` | Word not in verse | Red strikethrough |

### 4. Display Modes

The feature has two display modes based on accuracy threshold (70%):

**Detailed Mode (accuracy >= 70%):**
- Shows all word statuses with inline corrections
- Wrong words show expected word next to them
- Missing words appear in sequence

**Highlight-Only Mode (accuracy < 70%):**
- Only shows spoken words
- Errors highlighted with subtle background
- Less visual clutter for struggling users
- Automatically shows correct verse text

### 5. Real-Time vs Final Accuracy

**Real-Time (during recitation):**
```
accuracy = correctWords / wordsSpokenSoFar * 100
```
- Encouraging feedback while speaking
- Filters out trailing missing words (not reached yet)

**Final (after recording stops):**
```
accuracy = correctWords / totalVerseWords * 100
```
- Penalizes omitting words at the end
- Used for suggested rating calculation

### 6. Rating Suggestion

| Accuracy | Suggested Rating |
|----------|-----------------|
| >= 95%   | 5 |
| >= 85%   | 4 |
| >= 70%   | 3 |
| >= 50%   | 2 |
| < 50%    | 1 |

The suggested rating button pulses with a green glow animation.

## CSS Classes

### Layout Classes

| Class | Purpose |
|-------|---------|
| `.voice-practice` | Main container, adds `position: relative` |
| `.voice-header` | Flexbox row for verse reference and passage title |
| `.voice-reference` | Centered verse reference display |
| `.passage-title-container` | Absolutely positioned passage title (top right) |
| `.voice-controls` | Microphone button and status text |
| `.voice-transcription-wrapper` | Container for transcription box |
| `.voice-transcription` | The recitation display box |
| `.voice-nav` | Rating buttons and controls |

### Word Status Classes

| Class | Purpose |
|-------|---------|
| `.word-correct` | Correctly spoken word (inherits color) |
| `.word-wrong` | Wrong word (red, strikethrough) |
| `.word-missing` | Skipped word (green, underline) |
| `.word-extra` | Extra word (red, strikethrough) |
| `.word-expected` | Expected word shown after wrong (green) |
| `.word-error` | Highlight-only mode error (light red background) |

### Interactive Classes

| Class | Purpose |
|-------|---------|
| `.mic-button` | Microphone button base style |
| `.mic-button.recording` | Active recording state (red, pulsing) |
| `.rating-suggested` | Pulsing green glow on suggested rating |
| `#verse-answer.visible` | Shows the correct verse text |

## Web Speech API Integration

```javascript
var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
var recognition = new SpeechRecognition();

recognition.continuous = true;      // Don't stop after first result
recognition.interimResults = true;  // Get partial results
recognition.lang = 'en-US';         // English language

// Events
recognition.onstart    // Recording started
recognition.onend      // Recording stopped
recognition.onresult   // Speech recognized (interim or final)
recognition.onerror    // Error occurred
```

**Browser Compatibility:**
| Browser | Support |
|---------|---------|
| Chrome | Full support |
| Edge | Full support |
| Safari | Partial (webkit prefix) |
| Firefox | Not supported |

## Testing

### Unit Tests (Vitest)

**Location:** `test/javascript/voice_comparison.test.js`

**Run:** `npm run test:run` or `npm test`

**Coverage:** 153+ tests covering:
- `scrubText()` - Text normalization
- `flexibleTextMatch()` - Apostrophes, quotes, punctuation
- `normalizeText()` / `getWordArray()` - Text processing
- `compareVerses()` - Basic sequential comparison
- `compareVersesLCS()` - LCS-based comparison
- `compareVersesWithLCS()` - LCS + substitution detection
- `greedyAlign()` - Suffix LCS alignment algorithm
- `filterTrailingMissing()` - Real-time display filtering
- `calculateAccuracy()` / `getSuggestedRating()` - Scoring
- `renderComparison()` / `renderComparisonHighlightOnly()` - HTML rendering

**Key Test Cases:**
- Wrong first word doesn't cascade errors
- Repeated phrases match to earliest occurrence
- Omitted words in middle are detected
- Substitutions are detected correctly
- Apostrophe variations handled

### Controller Tests (RSpec)

**Location:** `spec/controllers/memverses_controller_spec.rb:334`

**Run:** `bundle exec rspec spec/controllers/memverses_controller_spec.rb`

## Configuration

### Accuracy Threshold

```javascript
var HIGHLIGHT_ONLY_THRESHOLD = 70;
```

Controls when to switch between detailed and highlight-only display modes.

### Rating Thresholds

In `getSuggestedRating()`:
```javascript
if (accuracy >= 95) return 5;
if (accuracy >= 85) return 4;
if (accuracy >= 70) return 3;
if (accuracy >= 50) return 2;
return 1;
```

## Dependencies

### JavaScript
- jQuery (global `$`)
- `flexibleTextMatch()` from `memverse_lib.js` (global)
- `scrub_text()` from `memverse_lib.js` (global)
- `mvDue()` from `memverse_lib.js` (global)
- `log_progress()` from `memverse_lib.js` (global)

### CSS
- Inherits from `mv_passage.scss` (`.main-verse-review`, `.passage-entry`)
- Uses colors from style guide (`#6b9620`, `#65a30d`, `#aa0101`)

## Future Enhancements

### Planned
1. **Text-to-Speech (TTS):** Read verse aloud to user before recitation
2. **AJAX Navigation:** Load next verse without page interaction
3. **Session Tracking:** Record voice practice sessions in user progress
4. **Multiple Languages:** Support non-English verses

### Possible Improvements
1. **Confidence Scores:** Use Web Speech API confidence values
2. **Phonetic Matching:** Handle homophones (there/their/they're)
3. **Verse Segments:** Practice portions of long verses
4. **Audio Recording:** Save recordings for later review
5. **Offline Support:** Cache verses for offline practice

## Troubleshooting

### "Speech recognition not supported"
- Use Chrome or Edge browser
- Check browser is up to date

### "Microphone access denied"
- Click browser's permission icon
- Allow microphone access for the site
- Check system microphone permissions

### Words not recognized correctly
- Speak clearly and at moderate pace
- Check microphone is working in other apps
- Try a different microphone

### Accuracy seems too low
- The algorithm is strict about word order
- Minor pronunciation variations should be handled
- Check for extra words or different phrasing

## Code Maintenance Notes

### Inline vs Module Code

The comparison algorithm exists in two places:
1. **Inline in view** (`voice_practice.html.erb`) - ES5 syntax, used at runtime
2. **ES6 module** (`voice_comparison.js`) - For Vitest testing

When modifying the algorithm, **update both locations** to keep them in sync.

### Why Inline JavaScript?

The voice practice view uses inline JavaScript because:
- Web Speech API can't be easily mocked in tests
- Tight coupling between DOM and speech events
- Single-page feature with no module dependencies
- Avoids asset pipeline complexity

### CSS Organization

All styles are in `mv_voice_practice.scss`. The file uses:
- SCSS nesting for related elements
- Hardcoded colors (not variables) to match existing site theme
- Inheritance from `mv_passage.scss` for layout consistency
