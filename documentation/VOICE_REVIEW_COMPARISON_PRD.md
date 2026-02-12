# Voice Review: Real-time Verse Comparison Feature

## Overview
Compare the user's transcribed speech to the actual verse text in real-time and visually highlight errors to help users identify mistakes in their recitation.

---

## Requirements

### Comparison Behavior
- **Timing**: Comparison happens automatically in real-time as the user speaks
- **Display**: Only highlight errors in the transcription (do not show the full correct verse)
- **Matching**: Strict matching (exact word-for-word comparison)
- **Rating**: Accuracy percentage influences the suggested rating

---

## Text Normalization

Before comparison, both texts are normalized:
- Convert to lowercase
- Remove punctuation (periods, commas, colons, semicolons, quotes, parentheses)
- Normalize whitespace (multiple spaces → single space)
- Trim leading/trailing whitespace

**Note**: Matching is strict after normalization. No fuzzy matching or substitution handling (e.g., "4" ≠ "for").

---

## Comparison Algorithm

Word-by-word comparison using a diff algorithm:

1. Split both normalized texts into word arrays
2. Compare words sequentially
3. Identify word status:
   - **Correct**: Word matches expected word at this position
   - **Wrong**: Word does not match expected word (substitution)
   - **Missing**: Expected word not present in spoken text (omission)
   - **Extra**: Spoken word not present in expected text (insertion)

---

## Visual Display

Errors are highlighted in the transcription area:

| Status | Styling |
|--------|---------|
| Correct | Normal text (default color) |
| Wrong | Red text with strikethrough, expected word in green |
| Missing | Green text with underline (inserted at correct position) |
| Extra | Red text with strikethrough |

### CSS Classes
```css
.word-correct { }
.word-wrong { color: #aa0101; text-decoration: line-through; }  /* red-bright */
.word-missing { color: #65a30d; text-decoration: underline; }   /* green-medium */
.word-extra { color: #aa0101; text-decoration: line-through; }  /* red-bright */
.word-expected { color: #65a30d; margin-left: 4px; }            /* green-medium */
```

---

## Accuracy Calculation

```
accuracy = (correct_words / total_expected_words) * 100
```

Where:
- `correct_words` = number of words that match exactly
- `total_expected_words` = total words in the actual verse

---

## Suggested Rating Based on Accuracy

| Accuracy | Suggested Rating | Visual Indicator |
|----------|------------------|------------------|
| 95-100%  | 5                | Highlight "5" button |
| 85-94%   | 4                | Highlight "4" button |
| 70-84%   | 3                | Highlight "3" button |
| 50-69%   | 2                | Highlight "2" button |
| 0-49%    | 1                | Highlight "1" button |

The suggested rating button should be visually highlighted (e.g., pulsing border or background color) but the user can still choose any rating.

---

## Implementation Components

### 1. JavaScript Functions

**`normalizeText(text)`**
- Input: Raw text string
- Output: Normalized string (lowercase, no punctuation, single spaces)

**`getWordArray(text)`**
- Input: Normalized text
- Output: Array of words

**`compareVerses(spokenWords, actualWords)`**
- Input: Two word arrays
- Output: Array of comparison objects
  ```javascript
  [
    { word: "the", status: "correct" },
    { word: "lrod", status: "wrong", expected: "lord" },
    { word: "is", status: "missing" },
    { word: "um", status: "extra" },
    ...
  ]
  ```

**`calculateAccuracy(comparisonResult, totalExpectedWords)`**
- Input: Comparison result array, total expected word count
- Output: Accuracy percentage (0-100)

**`getSuggestedRating(accuracy)`**
- Input: Accuracy percentage
- Output: Suggested rating (1-5)

**`renderComparison(comparisonResult)`**
- Input: Comparison result array
- Output: HTML string with styled words
- Updates the transcription display area

**`highlightSuggestedRating(rating)`**
- Input: Rating number (1-5)
- Adds visual highlight to the suggested rating button

### 2. Event Integration

Update the existing `recognition.onresult` handler:
1. After updating the transcription text, call comparison functions
2. Render the comparison result instead of plain text
3. Calculate accuracy and update suggested rating highlight

### 3. UI Elements

- Accuracy percentage display (e.g., "Accuracy: 87%")
- Suggested rating highlight on the 1-5 buttons
- Legend/key for color coding (optional, can be tooltip)

---

## User Flow

1. User sees verse reference (e.g., "John 3:16 [NIV]")
2. User clicks microphone button
3. User begins reciting the verse
4. **Real-time**: As words are transcribed:
   - Each word is compared to the expected verse
   - Correct words appear in normal text
   - Errors are highlighted immediately (wrong/missing/extra)
   - Accuracy percentage updates continuously
   - Suggested rating button is highlighted
5. User stops recording
6. Final comparison and accuracy displayed
7. User selects a rating (suggested one is highlighted)
8. Next verse loads

---

## Edge Cases

1. **Empty transcription**: No comparison, accuracy = 0%
2. **Partial recitation**: Compare only spoken portion, missing words shown
3. **Extra words at end**: Mark as extra (red strikethrough)
4. **Speech recognition errors**: Treated as wrong words (strict matching)
5. **Interim vs final results**: Only compare final results to avoid flickering

---

## Future Enhancements (Out of Scope)

- Fuzzy matching for similar words
- Audio playback of correct pronunciation
- Word-level timing analysis
- Practice mode focusing on commonly missed words
- Statistics tracking over time
