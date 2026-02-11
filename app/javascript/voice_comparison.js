/**
 * Voice Review Verse Comparison
 *
 * Compares user's spoken verse transcription to the actual verse text
 * and provides visual feedback on accuracy.
 */

/**
 * Normalize text for comparison
 * - Convert to lowercase
 * - Remove punctuation (periods, commas, colons, semicolons, quotes, parentheses)
 * - Normalize whitespace (multiple spaces to single space)
 * - Trim leading/trailing whitespace
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
    .replace(/[.,;:'"()]/g, '') // Remove punctuation
    .replace(/\s+/g, ' ')        // Normalize whitespace
    .trim();                      // Trim leading/trailing whitespace
}

/**
 * Split normalized text into array of words
 *
 * @param {string} text - Normalized text
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
 * - Compare word by word sequentially
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

    // Words match - correct
    if (spoken === actual) {
      result.push({ word: spoken, status: 'correct' });
      i++;
      j++;
      continue;
    }

    // Words don't match - need to determine if wrong, missing, or extra
    // Look ahead to see if this is an insertion (extra) or substitution (wrong)
    const nextSpokenMatchesActual = spokenWords[i + 1] === actual;
    const spokenMatchesNextActual = spoken === actualWords[j + 1];

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
