/**
 * Voice Review Verse Comparison
 *
 * Compares user's spoken verse transcription to the actual verse text
 * and provides visual feedback on accuracy.
 *
 * Uses the same text matching logic as the passage review feature
 * (flexibleTextMatch from memverse_lib.js) to handle apostrophes,
 * contractions, and other punctuation variations.
 */

/**
 * Scrub text for comparison - removes all non-alphanumeric characters
 * This mirrors the scrub_text function in memverse_lib.js
 *
 * @param {string} text - Raw text to scrub
 * @returns {string} Scrubbed text (lowercase, alphanumeric only)
 */
export function scrubText(text) {
  if (!text || typeof text !== 'string') {
    return '';
  }
  return text
    .toLowerCase()
    .replace(/[^0-9a-z\u00BF-\u1FFF\u2C00-\uD7FF]+/g, '');
}

/**
 * Homophone dictionary for voice comparison
 *
 * Maps each word to a Set of its homophones for O(1) lookup.
 * When the speech-to-text API transcribes a word as a homophone
 * of the expected word, we accept it as correct since the user
 * spoke the right sound.
 *
 * All keys and values are lowercase.
 */
export const HOMOPHONES = {
  // there / their / they're
  "there": new Set(["their", "they're"]),
  "their": new Set(["there", "they're"]),
  "they're": new Set(["there", "their"]),
  // through / threw / thru
  "through": new Set(["threw", "thru"]),
  "threw": new Set(["through", "thru"]),
  "thru": new Set(["through", "threw"]),
  // know / no
  "know": new Set(["no"]),
  "no": new Set(["know"]),
  // hear / here
  "hear": new Set(["here"]),
  "here": new Set(["hear"]),
  // peace / piece
  "peace": new Set(["piece"]),
  "piece": new Set(["peace"]),
  // soul / sole
  "soul": new Set(["sole"]),
  "sole": new Set(["soul"]),
  // son / sun
  "son": new Set(["sun"]),
  "sun": new Set(["son"]),
  // whole / hole
  "whole": new Set(["hole"]),
  "hole": new Set(["whole"]),
  // holy / wholly
  "holy": new Set(["wholly"]),
  "wholly": new Set(["holy"]),
  // altar / alter
  "altar": new Set(["alter"]),
  "alter": new Set(["altar"]),
  // prophet / profit
  "prophet": new Set(["profit"]),
  "profit": new Set(["prophet"]),
  // reign / rain / rein
  "reign": new Set(["rain", "rein"]),
  "rain": new Set(["reign", "rein"]),
  "rein": new Set(["reign", "rain"]),
  // pray / prey
  "pray": new Set(["prey"]),
  "prey": new Set(["pray"]),
  // right / write / rite
  "right": new Set(["write", "rite"]),
  "write": new Set(["right", "rite"]),
  "rite": new Set(["right", "write"]),
  // way / weigh
  "way": new Set(["weigh"]),
  "weigh": new Set(["way"]),
  // one / won
  "one": new Set(["won"]),
  "won": new Set(["one"]),
  // see / sea
  "see": new Set(["sea"]),
  "sea": new Set(["see"]),
  // him / hymn
  "him": new Set(["hymn"]),
  "hymn": new Set(["him"]),
  // heal / heel
  "heal": new Set(["heel"]),
  "heel": new Set(["heal"]),
  // night / knight
  "night": new Set(["knight"]),
  "knight": new Set(["night"]),
  // born / borne
  "born": new Set(["borne"]),
  "borne": new Set(["born"]),
  // die / dye
  "die": new Set(["dye"]),
  "dye": new Set(["die"]),
  // great / grate
  "great": new Set(["grate"]),
  "grate": new Set(["great"]),
  // flee / flea
  "flee": new Set(["flea"]),
  "flea": new Set(["flee"]),
  // raised / razed
  "raised": new Set(["razed"]),
  "razed": new Set(["raised"]),
  // hour / our
  "hour": new Set(["our"]),
  "our": new Set(["hour"]),
  // knot / not
  "knot": new Set(["not"]),
  "not": new Set(["knot"]),
  // be / bee
  "be": new Set(["bee"]),
  "bee": new Set(["be"]),
  // by / buy / bye
  "by": new Set(["buy", "bye"]),
  "buy": new Set(["by", "bye"]),
  "bye": new Set(["by", "buy"]),
  // for / four / fore
  "for": new Set(["four", "fore"]),
  "four": new Set(["for", "fore"]),
  "fore": new Set(["for", "four"]),
  // to / too / two
  "to": new Set(["too", "two"]),
  "too": new Set(["to", "two"]),
  "two": new Set(["to", "too"]),
  // in / inn
  "in": new Set(["inn"]),
  "inn": new Set(["in"]),
  // i / eye
  "i": new Set(["eye"]),
  "eye": new Set(["i"]),
  // we / wee
  "we": new Set(["wee"]),
  "wee": new Set(["we"]),
  // meat / meet
  "meat": new Set(["meet"]),
  "meet": new Set(["meat"]),
  // read / reed (present tense)
  "read": new Set(["reed"]),
  "reed": new Set(["read"]),
  // lead / led (past tense)
  "lead": new Set(["led"]),
  "led": new Set(["lead"]),
  // would / wood
  "would": new Set(["wood"]),
  "wood": new Set(["would"]),
  // which / witch
  "which": new Set(["witch"]),
  "witch": new Set(["which"]),
  // where / wear / ware
  "where": new Set(["wear", "ware"]),
  "wear": new Set(["where", "ware"]),
  "ware": new Set(["where", "wear"]),
};

/**
 * Strip trailing and leading punctuation from a word for homophone comparison
 *
 * @param {string} word - Word possibly with punctuation
 * @returns {string} Word with punctuation stripped
 */
function stripPunctuation(word) {
  return word.replace(/^[^a-zA-Z']+|[^a-zA-Z']+$/g, '');
}

/**
 * Flexible text matching for word comparison
 * This mirrors the flexibleTextMatch function in memverse_lib.js
 *
 * Handles common variations:
 * - Case insensitive matching
 * - Apostrophe words: "gods" matches "God's", "dont" matches "don't"
 * - Quotation marks: "The" matches '"The'
 * - Falls back to scrubText comparison for other cases
 *
 * @param {string} correctWord - The expected word from the verse
 * @param {string} userInput - The word from user's speech
 * @returns {boolean} True if words match flexibly
 */
export function flexibleTextMatch(correctWord, userInput) {
  if (!correctWord || !userInput) {
    return false;
  }

  // First, check for exact match (case-insensitive)
  if (correctWord.toLowerCase() === userInput.toLowerCase()) {
    return true;
  }

  // Handle apostrophe words - accept word without apostrophes
  // e.g., "childrens" matches "children's", "gods" matches "God's"
  if (correctWord.includes("'") || correctWord.includes("\u2019")) {
    const withoutApostrophes = correctWord.replace(/['\u2019]/g, '');
    if (withoutApostrophes.toLowerCase() === userInput.toLowerCase()) {
      return true;
    }
  }

  // Handle quotation marks at beginning
  // e.g., "The" matches '"The' or '\u201CThe'
  if (correctWord.match(/^["'\u201C\u2018\u201D]/)) {
    const withoutQuote = correctWord.replace(/^["'\u201C\u2018\u201D]/, '');
    if (withoutQuote.toLowerCase() === userInput.toLowerCase()) {
      return true;
    }
  }

  // For all other cases, use scrubText comparison
  return scrubText(correctWord) === scrubText(userInput);
}

/**
 * Check whether two words are homophones
 *
 * @param {string} wordA - first word (may include punctuation)
 * @param {string} wordB - second word (may include punctuation)
 * @returns {boolean}
 */
export function isHomophone(wordA, wordB) {
  const a = stripPunctuation(wordA).toLowerCase();
  const b = stripPunctuation(wordB).toLowerCase();
  return !!(HOMOPHONES[a] && HOMOPHONES[a].has(b));
}

/**
 * Voice-aware flexible text match
 *
 * Wraps flexibleTextMatch with an additional homophone check.
 * This keeps the typed-review matching untouched while allowing the
 * voice pipeline to accept speech-to-text homophone transcriptions.
 *
 * @param {string} correctWord - The expected word from the verse
 * @param {string} userInput - The word from user's speech
 * @returns {boolean} True if words match flexibly or are homophones
 */
export function voiceFlexibleTextMatch(correctWord, userInput) {
  if (flexibleTextMatch(correctWord, userInput)) {
    return true;
  }
  if (!correctWord || !userInput) {
    return false;
  }
  return isHomophone(correctWord, userInput);
}

/**
 * Normalize text for splitting into words
 * - Convert to lowercase
 * - Normalize whitespace (multiple spaces to single space)
 * - Trim leading/trailing whitespace
 *
 * Note: We preserve punctuation here because flexibleTextMatch handles it
 *
 * @param {string} text - Raw text to normalize
 * @returns {string} Normalized text
 */
export function normalizeText(text) {
  if (!text || typeof text !== 'string') {
    return '';
  }

  return text
    .toLowerCase()
    .replace(/\s+/g, ' ')        // Normalize whitespace
    .trim();                      // Trim leading/trailing whitespace
}

/**
 * Split text into array of words
 *
 * @param {string} text - Text to split
 * @returns {string[]} Array of words
 */
export function getWordArray(text) {
  if (!text || typeof text !== 'string') {
    return [];
  }

  const normalized = normalizeText(text);
  if (normalized === '') {
    return [];
  }

  return normalized.split(' ');
}

/**
 * Compare spoken words to actual verse words using sequential diff algorithm
 *
 * Algorithm:
 * - Compare word by word sequentially using flexibleTextMatch
 * - Track insertions (extra words) and deletions (missing words)
 * - Mark substitutions (wrong words)
 *
 * @param {string[]} spokenWords - Array of words from user's speech
 * @param {string[]} actualWords - Array of words from correct verse
 * @returns {Array<{word: string, status: string, expected?: string}>} Comparison result
 */
export function compareVerses(spokenWords, actualWords) {
  const result = [];

  // Handle empty cases
  if (!actualWords || actualWords.length === 0) {
    // No actual verse to compare against
    spokenWords.forEach(word => {
      result.push({ word, status: 'extra' });
    });
    return result;
  }

  if (!spokenWords || spokenWords.length === 0) {
    // Nothing spoken, all words are missing
    actualWords.forEach(word => {
      result.push({ word, status: 'missing' });
    });
    return result;
  }

  // Simple sequential diff algorithm
  let i = 0; // Index in spokenWords
  let j = 0; // Index in actualWords

  while (i < spokenWords.length || j < actualWords.length) {
    const spoken = spokenWords[i];
    const actual = actualWords[j];

    // Both arrays exhausted
    if (i >= spokenWords.length && j >= actualWords.length) {
      break;
    }

    // Spoken array exhausted - remaining words are missing
    if (i >= spokenWords.length) {
      result.push({ word: actual, status: 'missing' });
      j++;
      continue;
    }

    // Actual array exhausted - remaining words are extra
    if (j >= actualWords.length) {
      result.push({ word: spoken, status: 'extra' });
      i++;
      continue;
    }

    // Words match - correct (using voice-aware matching for apostrophes, homophones, etc.)
    if (voiceFlexibleTextMatch(actual, spoken)) {
      result.push({ word: spoken, status: 'correct' });
      i++;
      j++;
      continue;
    }

    // Words don't match - need to determine if wrong, missing, or extra
    // Look ahead to see if this is an insertion (extra) or substitution (wrong)
    const nextSpokenMatchesActual = spokenWords[i + 1] && voiceFlexibleTextMatch(actual, spokenWords[i + 1]);
    const spokenMatchesNextActual = actualWords[j + 1] && voiceFlexibleTextMatch(actualWords[j + 1], spoken);

    if (nextSpokenMatchesActual && !spokenMatchesNextActual) {
      // Current spoken word is extra, next spoken word matches current actual
      result.push({ word: spoken, status: 'extra' });
      i++;
    } else if (spokenMatchesNextActual && !nextSpokenMatchesActual) {
      // Current actual word is missing, current spoken matches next actual
      result.push({ word: actual, status: 'missing' });
      j++;
    } else {
      // Substitution - wrong word
      result.push({ word: spoken, status: 'wrong', expected: actual });
      i++;
      j++;
    }
  }

  return result;
}

/**
 * Calculate accuracy percentage based on comparison result
 *
 * Accuracy = (correct_words / total_expected_words) * 100
 *
 * @param {Array<{word: string, status: string}>} comparisonResult - Result from compareVerses
 * @param {number} totalExpectedWords - Total number of words in actual verse
 * @returns {number} Accuracy percentage (0-100)
 */
export function calculateAccuracy(comparisonResult, totalExpectedWords) {
  if (!comparisonResult || comparisonResult.length === 0 || totalExpectedWords === 0) {
    return 0;
  }

  const correctWords = comparisonResult.filter(item => item.status === 'correct').length;
  const accuracy = (correctWords / totalExpectedWords) * 100;

  return Math.round(accuracy * 100) / 100; // Round to 2 decimal places
}

/**
 * Get suggested rating based on accuracy percentage
 *
 * @param {number} accuracy - Accuracy percentage (0-100)
 * @returns {number} Suggested rating (1-5)
 */
export function getSuggestedRating(accuracy) {
  if (accuracy >= 95) return 5;
  if (accuracy >= 85) return 4;
  if (accuracy >= 70) return 3;
  if (accuracy >= 50) return 2;
  return 1;
}

/**
 * Render comparison result as HTML with appropriate CSS classes
 *
 * @param {Array<{word: string, status: string, expected?: string}>} comparisonResult - Result from compareVerses
 * @returns {string} HTML string with styled words
 */
export function renderComparison(comparisonResult) {
  if (!comparisonResult || comparisonResult.length === 0) {
    return '';
  }

  const htmlParts = comparisonResult.map(item => {
    const { word, status, expected } = item;

    switch (status) {
      case 'correct':
        return `<span class="word-correct">${escapeHtml(word)}</span>`;

      case 'wrong':
        // Show wrong word (strikethrough) followed by expected word (green)
        return `<span class="word-wrong">${escapeHtml(word)}</span><span class="word-expected">${escapeHtml(expected)}</span>`;

      case 'missing':
        // Show missing word with underline
        return `<span class="word-missing">${escapeHtml(word)}</span>`;

      case 'extra':
        // Show extra word with strikethrough
        return `<span class="word-extra">${escapeHtml(word)}</span>`;

      default:
        return `<span>${escapeHtml(word)}</span>`;
    }
  });

  return htmlParts.join(' ');
}

/**
 * Filter out trailing missing words from comparison result
 *
 * During real-time recitation, we don't want to show missing words
 * that come AFTER all spoken words (they haven't been reached yet).
 * We only want to show missing words that were skipped IN THE MIDDLE
 * of the recitation.
 *
 * @param {Array<{word: string, status: string, expected?: string}>} comparisonResult - Result from compareVerses
 * @returns {Array<{word: string, status: string, expected?: string}>} Filtered result with trailing missing removed
 */
export function filterTrailingMissing(comparisonResult) {
  if (!comparisonResult || comparisonResult.length === 0) {
    return [];
  }

  // Find the maximum verse position (actualIdx) among spoken words (correct or wrong)
  // This represents how far the user has progressed in the verse
  //
  // IMPORTANT: We filter based on VERSE POSITION (actualIdx), not array position.
  // This handles cases where repeated phrases cause LCS to match later occurrences,
  // which would otherwise show many "missing" words in the middle.
  //
  // Example: If verse has "walk in it" twice and user says "walking in it",
  // LCS might match "in it" to the second occurrence. Without verse-position
  // filtering, all words between the two occurrences would appear as "missing".
  let maxSpokenVersePosition = -1;
  let hasExtraWords = false;

  for (let i = 0; i < comparisonResult.length; i++) {
    const item = comparisonResult[i];
    // Only consider words that have a verse position (correct, wrong, missing)
    // and that represent user speech (correct, wrong - not missing)
    if ((item.status === 'correct' || item.status === 'wrong') && item.actualIdx !== undefined) {
      maxSpokenVersePosition = Math.max(maxSpokenVersePosition, item.actualIdx);
    }
    // Track if there are any extra words (user said something not in verse)
    if (item.status === 'extra') {
      hasExtraWords = true;
    }
  }

  // If no spoken words with verse positions found but there are extra words,
  // return only the extra words (user said something, just nothing that matches the verse)
  if (maxSpokenVersePosition === -1) {
    if (hasExtraWords) {
      return comparisonResult.filter(item => item.status === 'extra');
    }
    return [];
  }

  // Filter: keep words that are at or before the user's current verse position
  // This removes "missing" words that are beyond where the user has reached
  return comparisonResult.filter(item => {
    // Extra words (spoken but not in verse) have no verse position - always keep
    if (item.actualIdx === undefined || item.actualIdx === -1) {
      return true;
    }
    // Keep words at or before the user's current position in the verse
    return item.actualIdx <= maxSpokenVersePosition;
  });
}

/**
 * Split text into array of words preserving original casing.
 * Only normalizes whitespace (no lowercasing).
 *
 * Companion to getWordArray() — use this to keep an original-cased
 * copy of the verse words for display after comparison.
 *
 * @param {string} text - Text to split
 * @returns {string[]} Array of words with original casing
 */
export function getOriginalWordArray(text) {
  if (!text || typeof text !== 'string') {
    return [];
  }
  const normalized = text.replace(/\s+/g, ' ').trim();
  if (normalized === '') {
    return [];
  }
  return normalized.split(' ');
}

/**
 * Restore original casing from the verse text in comparison results.
 *
 * The comparison pipeline lowercases all words via normalizeText() before
 * comparing. This function restores the original casing for display by
 * looking up each word's position in the original (un-lowercased) verse
 * words array using the actualIdx field.
 *
 * - 'correct' items: word is replaced with the original verse word
 * - 'missing' items: word is replaced with the original verse word
 * - 'wrong' items: expected is replaced with the original verse word
 * - 'extra' items: left unchanged (user's spoken word, no verse source)
 *
 * Returns a new array (does not mutate the input).
 *
 * @param {Array<{word: string, status: string, expected?: string, actualIdx?: number}>} comparisonResult
 * @param {string[]} originalVerseWords - Verse words with original casing
 * @returns {Array<{word: string, status: string, expected?: string, actualIdx?: number}>}
 */
export function restoreOriginalCasing(comparisonResult, originalVerseWords) {
  if (!comparisonResult || comparisonResult.length === 0 || !originalVerseWords) {
    return comparisonResult || [];
  }

  return comparisonResult.map(item => {
    const idx = item.actualIdx;
    if (idx === undefined || idx === -1 || idx >= originalVerseWords.length) {
      return item;
    }

    const original = originalVerseWords[idx];

    if (item.status === 'correct' || item.status === 'missing') {
      return { ...item, word: original };
    }
    if (item.status === 'wrong') {
      return { ...item, expected: original };
    }
    return item;
  });
}

/**
 * Render comparison result in highlight-only mode
 *
 * This simplified view only shows the user's spoken words with errors highlighted.
 * Missing words are not shown inline - the user can see the correct verse separately.
 * Use this mode when accuracy is low to reduce visual clutter.
 *
 * @param {Array<{word: string, status: string, expected?: string}>} comparisonResult - Result from compareVerses
 * @returns {string} HTML string with error words highlighted
 */
export function renderComparisonHighlightOnly(comparisonResult) {
  if (!comparisonResult || comparisonResult.length === 0) {
    return '';
  }

  const htmlParts = comparisonResult
    .filter(item => item.status !== 'missing') // Only show spoken words
    .map(item => {
      const { word, status } = item;

      switch (status) {
        case 'correct':
          return `<span class="word-correct">${escapeHtml(word)}</span>`;

        case 'wrong':
        case 'extra':
          // Highlight errors with subtle background, no strikethrough or corrections
          return `<span class="word-error">${escapeHtml(word)}</span>`;

        default:
          return `<span>${escapeHtml(word)}</span>`;
      }
    });

  return htmlParts.join(' ');
}

/**
 * Escape HTML special characters to prevent XSS
 *
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Build LCS (Longest Common Subsequence) table using dynamic programming
 *
 * This creates a 2D table where lcs[i][j] represents the length of the
 * longest common subsequence between spokenWords[0..i-1] and actualWords[0..j-1]
 *
 * @param {string[]} spokenWords - Array of words from user's speech
 * @param {string[]} actualWords - Array of words from correct verse
 * @returns {number[][]} LCS table
 */
function buildLCSTable(spokenWords, actualWords) {
  const m = spokenWords.length;
  const n = actualWords.length;

  // Create table with (m+1) x (n+1) dimensions, initialized to 0
  const lcs = Array(m + 1).fill(null).map(() => Array(n + 1).fill(0));

  // Fill the table using dynamic programming
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (voiceFlexibleTextMatch(actualWords[j - 1], spokenWords[i - 1])) {
        // Words match - extend the subsequence
        lcs[i][j] = lcs[i - 1][j - 1] + 1;
      } else {
        // Words don't match - take the max from excluding either word
        lcs[i][j] = Math.max(lcs[i - 1][j], lcs[i][j - 1]);
      }
    }
  }

  return lcs;
}

/**
 * Greedy sequential alignment - always prefers earliest possible match
 *
 * This algorithm goes through spoken words in order and for each one,
 * finds the FIRST matching word in the actual verse starting from the
 * current position. This is more appropriate for sequential verse recitation
 * than standard LCS backtracking, which can match to later occurrences of
 * repeated words.
 *
 * Returns an array of operations that align spoken words with actual words.
 * Each operation is either:
 * - { type: 'match', spokenIdx, actualIdx } - words match
 * - { type: 'extra', spokenIdx } - extra spoken word (not in actual)
 * - { type: 'missing', actualIdx } - missing actual word (not spoken)
 *
 * @param {string[]} spokenWords - Array of words from user's speech
 * @param {string[]} actualWords - Array of words from correct verse
 * @returns {Array<{type: string, spokenIdx?: number, actualIdx?: number}>} Alignment operations
 */
function greedyAlign(spokenWords, actualWords) {
  // Build suffix LCS table: suffixLcs[i][j] = LCS length of spoken[i:] and actual[j:]
  const m = spokenWords.length;
  const n = actualWords.length;
  const suffixLcs = Array(m + 1).fill(null).map(() => Array(n + 1).fill(0));

  // Fill table from bottom-right to top-left
  for (let i = m - 1; i >= 0; i--) {
    for (let j = n - 1; j >= 0; j--) {
      if (voiceFlexibleTextMatch(actualWords[j], spokenWords[i])) {
        suffixLcs[i][j] = suffixLcs[i + 1][j + 1] + 1;
      } else {
        suffixLcs[i][j] = Math.max(suffixLcs[i + 1][j], suffixLcs[i][j + 1]);
      }
    }
  }

  // Forward alignment using suffix LCS to guide decisions
  const alignment = [];
  let i = 0; // spoken index
  let j = 0; // actual index

  while (i < m && j < n) {
    if (voiceFlexibleTextMatch(actualWords[j], spokenWords[i])) {
      // Words match - take the match
      alignment.push({ type: 'match', spokenIdx: i, actualIdx: j });
      i++;
      j++;
    } else {
      // Words don't match - decide whether to skip spoken or actual
      // Compare future LCS: which skip leads to better alignment?
      const skipSpokenFutureLcs = suffixLcs[i + 1][j];
      const skipActualFutureLcs = suffixLcs[i][j + 1];

      if (skipSpokenFutureLcs > skipActualFutureLcs) {
        // Skipping spoken word leads to better alignment - mark spoken as extra
        alignment.push({ type: 'extra', spokenIdx: i });
        i++;
      } else if (skipActualFutureLcs > skipSpokenFutureLcs) {
        // Skipping actual word leads to better alignment - mark actual as missing
        alignment.push({ type: 'missing', actualIdx: j });
        j++;
      } else {
        // Tie: prefer marking spoken as extra (user made mistake)
        alignment.push({ type: 'extra', spokenIdx: i });
        i++;
      }
    }
  }

  // Handle remaining spoken words (extras)
  while (i < m) {
    alignment.push({ type: 'extra', spokenIdx: i });
    i++;
  }

  // Handle remaining actual words (missing)
  while (j < n) {
    alignment.push({ type: 'missing', actualIdx: j });
    j++;
  }

  return alignment;
}

/**
 * Backtrack through LCS table to find the optimal alignment
 * NOTE: This is kept for reference but greedyAlign is preferred for voice review
 *
 * Returns an array of operations that align spoken words with actual words.
 * Each operation is either:
 * - { type: 'match', spokenIdx, actualIdx } - words match
 * - { type: 'extra', spokenIdx } - extra spoken word (not in actual)
 * - { type: 'missing', actualIdx } - missing actual word (not spoken)
 *
 * @param {number[][]} lcs - LCS table from buildLCSTable
 * @param {string[]} spokenWords - Array of words from user's speech
 * @param {string[]} actualWords - Array of words from correct verse
 * @returns {Array<{type: string, spokenIdx?: number, actualIdx?: number}>} Alignment operations
 */
function backtrackLCS(lcs, spokenWords, actualWords) {
  const alignment = [];
  let i = spokenWords.length;
  let j = actualWords.length;

  // Backtrack from bottom-right to top-left
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && voiceFlexibleTextMatch(actualWords[j - 1], spokenWords[i - 1])) {
      // Words match - they're part of the LCS
      alignment.unshift({ type: 'match', spokenIdx: i - 1, actualIdx: j - 1 });
      i--;
      j--;
    } else if (j > 0 && (i === 0 || lcs[i][j - 1] >= lcs[i - 1][j])) {
      // Actual word not matched - it's missing from spoken
      alignment.unshift({ type: 'missing', actualIdx: j - 1 });
      j--;
    } else {
      // Spoken word not matched - it's extra
      alignment.unshift({ type: 'extra', spokenIdx: i - 1 });
      i--;
    }
  }

  return alignment;
}

/**
 * Compare spoken words to actual verse words using greedy sequential alignment
 *
 * This algorithm uses greedy sequential matching to find the alignment between
 * spoken and actual words. It always prefers the EARLIEST possible match for
 * each spoken word, which is more appropriate for sequential verse recitation.
 *
 * For example, if a verse contains "walk in it" twice and the user says
 * "walking in it", the algorithm will match "in it" to the FIRST occurrence,
 * not the second.
 *
 * The algorithm also handles omissions correctly without cascading errors.
 * For example, if the user omits "and sisters" from Romans 12:1:
 * - Actual: "therefore i urge you brothers and sisters in view of..."
 * - Spoken: "therefore i urge you brothers in view of..."
 * It correctly identifies only "and sisters" as missing.
 *
 * @param {string[]} spokenWords - Array of words from user's speech
 * @param {string[]} actualWords - Array of words from correct verse
 * @returns {Array<{word: string, status: string, expected?: string}>} Comparison result
 */
export function compareVersesLCS(spokenWords, actualWords) {
  const result = [];

  // Handle empty cases
  if (!actualWords || actualWords.length === 0) {
    if (spokenWords && spokenWords.length > 0) {
      spokenWords.forEach(word => {
        result.push({ word, status: 'extra', actualIdx: -1 });
      });
    }
    return result;
  }

  if (!spokenWords || spokenWords.length === 0) {
    actualWords.forEach((word, idx) => {
      result.push({ word, status: 'missing', actualIdx: idx });
    });
    return result;
  }

  // Use greedy alignment to prefer earliest matches for repeated words
  const alignment = greedyAlign(spokenWords, actualWords);

  // Convert alignment to comparison result, tracking verse position (actualIdx)
  for (const op of alignment) {
    switch (op.type) {
      case 'match':
        result.push({ word: spokenWords[op.spokenIdx], status: 'correct', actualIdx: op.actualIdx });
        break;
      case 'missing':
        result.push({ word: actualWords[op.actualIdx], status: 'missing', actualIdx: op.actualIdx });
        break;
      case 'extra':
        result.push({ word: spokenWords[op.spokenIdx], status: 'extra', actualIdx: -1 });
        break;
    }
  }

  return result;
}

/**
 * Enhanced comparison that uses LCS for alignment, then detects substitutions
 *
 * This combines LCS alignment with substitution detection. When a spoken word
 * appears immediately adjacent to a missing actual word (no correct words between),
 * it's likely a substitution rather than separate extra/missing words.
 *
 * @param {string[]} spokenWords - Array of words from user's speech
 * @param {string[]} actualWords - Array of words from correct verse
 * @returns {Array<{word: string, status: string, expected?: string}>} Comparison result
 */
export function compareVersesWithLCS(spokenWords, actualWords) {
  // Get the basic LCS comparison
  const lcsResult = compareVersesLCS(spokenWords, actualWords);

  // Post-process to detect substitutions
  // A substitution is when an 'extra' word immediately precedes a 'missing' word
  // (or vice versa) with no 'correct' words between them
  const result = [];

  let i = 0;
  while (i < lcsResult.length) {
    const current = lcsResult[i];

    // Check for extra followed by missing (substitution pattern)
    if (current.status === 'extra' && i + 1 < lcsResult.length && lcsResult[i + 1].status === 'missing') {
      // This is a substitution: extra word where missing word should be
      result.push({
        word: current.word,
        status: 'wrong',
        expected: lcsResult[i + 1].word,
        actualIdx: lcsResult[i + 1].actualIdx  // Track verse position of substituted word
      });
      i += 2; // Skip both the extra and the missing
      continue;
    }

    // Check for missing followed by extra (substitution pattern - user said wrong word)
    // This is less common but can happen with certain alignments
    if (current.status === 'missing' && i + 1 < lcsResult.length && lcsResult[i + 1].status === 'extra') {
      // This is a substitution: the extra word replaces the missing word
      result.push({
        word: lcsResult[i + 1].word,
        status: 'wrong',
        expected: current.word,
        actualIdx: current.actualIdx  // Track verse position of substituted word
      });
      i += 2; // Skip both the missing and the extra
      continue;
    }

    // Not a substitution - keep as is
    result.push(current);
    i++;
  }

  return result;
}
