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
  if (correctWord.includes("'") || correctWord.includes("'")) {
    const withoutApostrophes = correctWord.replace(/['']/g, '');
    if (withoutApostrophes.toLowerCase() === userInput.toLowerCase()) {
      return true;
    }
  }

  // Handle quotation marks at beginning
  // e.g., "The" matches '"The' or '"The'
  if (correctWord.match(/^["'"'"]/)) {
    const withoutQuote = correctWord.replace(/^["'"'"]/, '');
    if (withoutQuote.toLowerCase() === userInput.toLowerCase()) {
      return true;
    }
  }

  // For all other cases, use scrubText comparison
  return scrubText(correctWord) === scrubText(userInput);
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

    // Words match - correct (using flexible matching for apostrophes, etc.)
    if (flexibleTextMatch(actual, spoken)) {
      result.push({ word: spoken, status: 'correct' });
      i++;
      j++;
      continue;
    }

    // Words don't match - need to determine if wrong, missing, or extra
    // Look ahead to see if this is an insertion (extra) or substitution (wrong)
    const nextSpokenMatchesActual = spokenWords[i + 1] && flexibleTextMatch(actual, spokenWords[i + 1]);
    const spokenMatchesNextActual = actualWords[j + 1] && flexibleTextMatch(actualWords[j + 1], spoken);

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

  // Find the index of the last "spoken" word (correct, wrong, or extra)
  // These are words that came from the user's speech
  let lastSpokenIndex = -1;

  for (let i = comparisonResult.length - 1; i >= 0; i--) {
    const status = comparisonResult[i].status;
    if (status === 'correct' || status === 'wrong' || status === 'extra') {
      lastSpokenIndex = i;
      break;
    }
  }

  // If no spoken words found (all missing), return empty array
  if (lastSpokenIndex === -1) {
    return [];
  }

  // Return only words up to and including the last spoken word
  return comparisonResult.slice(0, lastSpokenIndex + 1);
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
