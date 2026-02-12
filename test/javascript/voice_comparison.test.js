import { describe, it, expect } from 'vitest';
import { scrubText, flexibleTextMatch, normalizeText, getWordArray, compareVerses, compareVersesLCS, compareVersesWithLCS, calculateAccuracy, getSuggestedRating, renderComparison, renderComparisonHighlightOnly, filterTrailingMissing } from '../../app/javascript/voice_comparison.js';

describe('Voice Comparison Feature', () => {

  describe('scrubText', () => {
    it('converts text to lowercase', () => {
      expect(scrubText('Hello World')).toBe('helloworld');
    });

    it('removes all punctuation', () => {
      expect(scrubText("God's love")).toBe('godslove');
    });

    it('removes curly apostrophes', () => {
      expect(scrubText("God\u2019s love")).toBe('godslove');
    });

    it('removes periods and commas', () => {
      expect(scrubText('Hello, world.')).toBe('helloworld');
    });

    it('removes all non-alphanumeric characters', () => {
      expect(scrubText('Hello! "World" (test)')).toBe('helloworldtest');
    });

    it('preserves numbers', () => {
      expect(scrubText('John 3:16')).toBe('john316');
    });

    it('handles empty string', () => {
      expect(scrubText('')).toBe('');
    });

    it('handles null/undefined', () => {
      expect(scrubText(null)).toBe('');
      expect(scrubText(undefined)).toBe('');
    });

    it('preserves unicode letters', () => {
      // Spanish
      expect(scrubText('señor')).toBe('señor');
      // French
      expect(scrubText('café')).toBe('café');
    });
  });

  describe('flexibleTextMatch', () => {
    // Exact matches
    it('matches identical words', () => {
      expect(flexibleTextMatch('hello', 'hello')).toBe(true);
    });

    it('matches case-insensitively', () => {
      expect(flexibleTextMatch('Hello', 'hello')).toBe(true);
      expect(flexibleTextMatch('HELLO', 'hello')).toBe(true);
    });

    // Apostrophe handling - the main use case
    it('matches "gods" to "God\'s" (straight apostrophe)', () => {
      expect(flexibleTextMatch("God's", 'gods')).toBe(true);
    });

    it('matches "gods" to "God\u2019s" (curly apostrophe)', () => {
      expect(flexibleTextMatch("God\u2019s", 'gods')).toBe(true);
    });

    it('matches "dont" to "don\'t"', () => {
      expect(flexibleTextMatch("don't", 'dont')).toBe(true);
    });

    it('matches "childrens" to "children\'s"', () => {
      expect(flexibleTextMatch("children's", 'childrens')).toBe(true);
    });

    it('matches "im" to "I\'m"', () => {
      expect(flexibleTextMatch("I'm", 'im')).toBe(true);
    });

    it('matches "its" to "it\'s"', () => {
      expect(flexibleTextMatch("it's", 'its')).toBe(true);
    });

    // Quotation marks at beginning
    it('matches "The" to "\\"The" (with opening quote)', () => {
      expect(flexibleTextMatch('"The', 'The')).toBe(true);
    });

    it('matches "The" to ""The" (curly opening quote)', () => {
      expect(flexibleTextMatch('"The', 'The')).toBe(true);
    });

    // Scrub fallback for other punctuation
    it('matches words with trailing punctuation via scrub', () => {
      expect(flexibleTextMatch('world,', 'world')).toBe(true);
    });

    it('matches words with periods via scrub', () => {
      expect(flexibleTextMatch('end.', 'end')).toBe(true);
    });

    // Non-matches
    it('does not match completely different words', () => {
      expect(flexibleTextMatch('hello', 'world')).toBe(false);
    });

    it('does not match partial words', () => {
      expect(flexibleTextMatch('hello', 'hel')).toBe(false);
    });

    // Edge cases
    it('returns false for null/undefined inputs', () => {
      expect(flexibleTextMatch(null, 'test')).toBe(false);
      expect(flexibleTextMatch('test', null)).toBe(false);
      expect(flexibleTextMatch(null, null)).toBe(false);
    });

    it('returns false for empty strings', () => {
      expect(flexibleTextMatch('', 'test')).toBe(false);
      expect(flexibleTextMatch('test', '')).toBe(false);
    });
  });

  describe('normalizeText', () => {
    // Note: normalizeText now only lowercases and normalizes whitespace
    // Punctuation is preserved because flexibleTextMatch handles it during comparison

    it('converts text to lowercase', () => {
      expect(normalizeText('The LORD is my Shepherd')).toBe('the lord is my shepherd');
    });

    it('preserves punctuation (handled by flexibleTextMatch)', () => {
      expect(normalizeText('In the beginning. God created.')).toBe('in the beginning. god created.');
    });

    it('preserves apostrophes (handled by flexibleTextMatch)', () => {
      expect(normalizeText("God's love")).toBe("god's love");
    });

    it('normalizes multiple spaces to single space', () => {
      expect(normalizeText('In    the   beginning    God')).toBe('in the beginning god');
    });

    it('trims leading whitespace', () => {
      expect(normalizeText('   In the beginning')).toBe('in the beginning');
    });

    it('trims trailing whitespace', () => {
      expect(normalizeText('In the beginning   ')).toBe('in the beginning');
    });

    it('handles empty string', () => {
      expect(normalizeText('')).toBe('');
    });

    it('handles null/undefined', () => {
      expect(normalizeText(null)).toBe('');
      expect(normalizeText(undefined)).toBe('');
    });
  });

  describe('getWordArray', () => {
    it('splits text into words', () => {
      expect(getWordArray('the lord is my shepherd')).toEqual(['the', 'lord', 'is', 'my', 'shepherd']);
    });

    it('handles single word', () => {
      expect(getWordArray('word')).toEqual(['word']);
    });

    it('handles multiple spaces between words', () => {
      expect(getWordArray('the    lord    is')).toEqual(['the', 'lord', 'is']);
    });

    it('handles empty string and returns empty array', () => {
      expect(getWordArray('')).toEqual([]);
    });

    it('handles string with only spaces', () => {
      expect(getWordArray('   ')).toEqual([]);
    });

    it('preserves punctuation in words (handled by flexibleTextMatch)', () => {
      expect(getWordArray("God's love is great.")).toEqual(["god's", 'love', 'is', 'great.']);
    });
  });

  describe('compareVerses', () => {
    it('identifies all correct words', () => {
      const spokenWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result).toEqual([
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'correct' },
        { word: 'shepherd', status: 'correct' }
      ]);
    });

    it('identifies single wrong word', () => {
      const spokenWords = ['the', 'lrod', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'the', status: 'correct' });
      expect(result[1]).toEqual({ word: 'lrod', status: 'wrong', expected: 'lord' });
      expect(result[2]).toEqual({ word: 'is', status: 'correct' });
    });

    it('identifies missing word at start', () => {
      const spokenWords = ['lord', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'the', status: 'missing' });
      expect(result[1]).toEqual({ word: 'lord', status: 'correct' });
    });

    it('identifies missing word in middle', () => {
      const spokenWords = ['the', 'lord', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[2]).toEqual({ word: 'is', status: 'missing' });
    });

    it('identifies missing word at end', () => {
      const spokenWords = ['the', 'lord', 'is', 'my'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[result.length - 1]).toEqual({ word: 'shepherd', status: 'missing' });
    });

    it('identifies extra word at start', () => {
      const spokenWords = ['um', 'the', 'lord', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'um', status: 'extra' });
    });

    it('identifies extra word in middle', () => {
      const spokenWords = ['the', 'lord', 'um', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      const extraWord = result.find(r => r.word === 'um');
      expect(extraWord).toEqual({ word: 'um', status: 'extra' });
    });

    it('identifies extra word at end', () => {
      const spokenWords = ['the', 'lord', 'is', 'my', 'shepherd', 'amen'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[result.length - 1]).toEqual({ word: 'amen', status: 'extra' });
    });

    it('handles multiple errors', () => {
      const spokenWords = ['the', 'lrod', 'um', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      // Sequential diff algorithm treats non-matches as substitutions when lookahead doesn't find matches
      expect(result[0]).toEqual({ word: 'the', status: 'correct' });
      expect(result[1]).toEqual({ word: 'lrod', status: 'wrong', expected: 'lord' });
      // 'um' is treated as a substitution for 'is' (since next words don't align)
      expect(result[2]).toEqual({ word: 'um', status: 'wrong', expected: 'is' });
      expect(result[3]).toEqual({ word: 'my', status: 'correct' });
      expect(result[4]).toEqual({ word: 'shepherd', status: 'correct' });
    });

    it('handles empty spoken text (all words missing)', () => {
      const spokenWords = [];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result).toEqual([
        { word: 'the', status: 'missing' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'missing' },
        { word: 'my', status: 'missing' },
        { word: 'shepherd', status: 'missing' }
      ]);
    });

    it('handles empty actual text (all words extra)', () => {
      const spokenWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const actualWords = [];
      const result = compareVerses(spokenWords, actualWords);

      expect(result).toEqual([
        { word: 'the', status: 'extra' },
        { word: 'lord', status: 'extra' },
        { word: 'is', status: 'extra' },
        { word: 'my', status: 'extra' },
        { word: 'shepherd', status: 'extra' }
      ]);
    });

    it('handles complex real-world verse comparison', () => {
      const spokenWords = ['for', 'god', 'so', 'loved', 'world', 'that', 'he', 'gave', 'his', 'only', 'son'];
      const actualWords = ['for', 'god', 'so', 'loved', 'the', 'world', 'that', 'he', 'gave', 'his', 'one', 'and', 'only', 'son'];
      const result = compareVerses(spokenWords, actualWords);

      // Should detect missing "the" before "world" (lookahead finds 'world' matches next actual)
      expect(result.find(r => r.word === 'the' && r.status === 'missing')).toBeDefined();
      // Sequential diff treats 'only' as wrong (expected 'one') and 'son' as wrong (expected 'and')
      // because lookahead doesn't find alignment
      expect(result.find(r => r.word === 'only' && r.status === 'wrong')).toBeDefined();
      expect(result.find(r => r.word === 'son' && r.status === 'wrong')).toBeDefined();
      // 'only' and 'son' from actual verse end up as missing at the end
      expect(result.filter(r => r.status === 'missing').length).toBeGreaterThanOrEqual(1);
    });

    it('handles multiple consecutive missing words', () => {
      const spokenWords = ['the', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result.filter(r => r.status === 'missing')).toHaveLength(3);
    });

    it('handles multiple consecutive extra words', () => {
      const spokenWords = ['the', 'um', 'uh', 'er', 'lord'];
      const actualWords = ['the', 'lord'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result.filter(r => r.status === 'extra')).toHaveLength(3);
    });

    // Apostrophe handling tests - the key use case for flexibleTextMatch
    it('matches "gods" to "God\'s" as correct', () => {
      const spokenWords = ['gods', 'love'];
      const actualWords = ["god's", 'love'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'gods', status: 'correct' });
      expect(result[1]).toEqual({ word: 'love', status: 'correct' });
    });

    it('matches "dont" to "don\'t" as correct', () => {
      const spokenWords = ['dont', 'worry'];
      const actualWords = ["don't", 'worry'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'dont', status: 'correct' });
      expect(result[1]).toEqual({ word: 'worry', status: 'correct' });
    });

    it('matches "childrens" to "children\'s" as correct', () => {
      const spokenWords = ['the', 'childrens', 'toys'];
      const actualWords = ["the", "children's", 'toys'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'the', status: 'correct' });
      expect(result[1]).toEqual({ word: 'childrens', status: 'correct' });
      expect(result[2]).toEqual({ word: 'toys', status: 'correct' });
    });

    it('matches curly apostrophe words as correct', () => {
      const spokenWords = ['gods', 'love'];
      const actualWords = ["god\u2019s", 'love']; // curly apostrophe
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'gods', status: 'correct' });
    });

    it('handles quotation marks at start of words', () => {
      const spokenWords = ['the', 'word'];
      const actualWords = ['"the', 'word'];
      const result = compareVerses(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'the', status: 'correct' });
    });

    it('handles full verse with apostrophes correctly', () => {
      const spokenWords = ['for', 'gods', 'so', 'loved', 'the', 'world'];
      const actualWords = ['for', "god\u2019s", 'so', 'loved', 'the', 'world'];
      const result = compareVerses(spokenWords, actualWords);

      const correctCount = result.filter(r => r.status === 'correct').length;
      expect(correctCount).toBe(6);
    });
  });

  // ==========================================
  // LCS-based comparison tests
  // ==========================================

  describe('compareVersesLCS', () => {
    it('identifies all correct words', () => {
      const spokenWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVersesLCS(spokenWords, actualWords);

      expect(result).toEqual([
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'correct' },
        { word: 'shepherd', status: 'correct' }
      ]);
    });

    it('handles empty spoken text (all words missing)', () => {
      const spokenWords = [];
      const actualWords = ['the', 'lord', 'is'];
      const result = compareVersesLCS(spokenWords, actualWords);

      expect(result).toEqual([
        { word: 'the', status: 'missing' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'missing' }
      ]);
    });

    it('handles empty actual text (all words extra)', () => {
      const spokenWords = ['the', 'lord', 'is'];
      const actualWords = [];
      const result = compareVersesLCS(spokenWords, actualWords);

      expect(result).toEqual([
        { word: 'the', status: 'extra' },
        { word: 'lord', status: 'extra' },
        { word: 'is', status: 'extra' }
      ]);
    });

    it('identifies missing word in middle without cascading errors', () => {
      const spokenWords = ['the', 'lord', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVersesLCS(spokenWords, actualWords);

      // LCS should correctly identify only 'is' as missing
      expect(result).toEqual([
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'missing' },
        { word: 'my', status: 'correct' },
        { word: 'shepherd', status: 'correct' }
      ]);
    });

    it('identifies multiple missing words without cascading errors', () => {
      const spokenWords = ['the', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVersesLCS(spokenWords, actualWords);

      // Should correctly identify 3 missing words
      const missingWords = result.filter(r => r.status === 'missing');
      expect(missingWords.length).toBe(3);
      expect(missingWords.map(m => m.word)).toEqual(['lord', 'is', 'my']);

      const correctWords = result.filter(r => r.status === 'correct');
      expect(correctWords.length).toBe(2);
    });

    it('identifies extra word without cascading errors', () => {
      const spokenWords = ['the', 'lord', 'um', 'is', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVersesLCS(spokenWords, actualWords);

      // 'um' should be extra, everything else correct
      const extraWords = result.filter(r => r.status === 'extra');
      expect(extraWords.length).toBe(1);
      expect(extraWords[0].word).toBe('um');

      const correctWords = result.filter(r => r.status === 'correct');
      expect(correctWords.length).toBe(5);
    });

    // ==========================================
    // Cascading error prevention tests
    // ==========================================

    describe('cascading error prevention', () => {
      it('handles Romans 12:1 "and sisters" omission correctly', () => {
        // This is the specific case that caused the cascading error problem
        const actualWords = [
          'therefore', 'i', 'urge', 'you', 'brothers', 'and', 'sisters',
          'in', 'view', 'of', 'gods', 'mercy', 'to', 'offer', 'your',
          'bodies', 'as', 'a', 'living', 'sacrifice', 'holy', 'and',
          'pleasing', 'to', 'god', 'this', 'is', 'your', 'true', 'and',
          'proper', 'worship'
        ];
        const spokenWords = [
          'therefore', 'i', 'urge', 'you', 'brothers',
          'in', 'view', 'of', 'gods', 'mercy', 'to', 'offer', 'your',
          'bodies', 'as', 'a', 'living', 'sacrifice', 'holy', 'and',
          'pleasing', 'to', 'god', 'this', 'is', 'your', 'true', 'and',
          'proper', 'worship'
        ];
        const result = compareVersesLCS(spokenWords, actualWords);

        // Should identify exactly 2 missing words: 'and' and 'sisters'
        const missingWords = result.filter(r => r.status === 'missing');
        expect(missingWords.length).toBe(2);
        expect(missingWords[0].word).toBe('and');
        expect(missingWords[1].word).toBe('sisters');

        // All other words should be correct
        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(30);

        // No words should be marked as wrong or extra
        const wrongWords = result.filter(r => r.status === 'wrong');
        expect(wrongWords.length).toBe(0);

        const extraWords = result.filter(r => r.status === 'extra');
        expect(extraWords.length).toBe(0);
      });

      it('handles omission of "the" in John 3:16 correctly', () => {
        // "For God so loved world" instead of "For God so loved the world"
        const actualWords = ['for', 'god', 'so', 'loved', 'the', 'world'];
        const spokenWords = ['for', 'god', 'so', 'loved', 'world'];
        const result = compareVersesLCS(spokenWords, actualWords);

        const missingWords = result.filter(r => r.status === 'missing');
        expect(missingWords.length).toBe(1);
        expect(missingWords[0].word).toBe('the');

        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(5);
      });

      it('handles omission at the beginning correctly', () => {
        // "Lord is my shepherd" instead of "The Lord is my shepherd"
        const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
        const spokenWords = ['lord', 'is', 'my', 'shepherd'];
        const result = compareVersesLCS(spokenWords, actualWords);

        const missingWords = result.filter(r => r.status === 'missing');
        expect(missingWords.length).toBe(1);
        expect(missingWords[0].word).toBe('the');

        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(4);
      });

      it('handles omission at the end correctly', () => {
        // "The Lord is my" instead of "The Lord is my shepherd"
        const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
        const spokenWords = ['the', 'lord', 'is', 'my'];
        const result = compareVersesLCS(spokenWords, actualWords);

        const missingWords = result.filter(r => r.status === 'missing');
        expect(missingWords.length).toBe(1);
        expect(missingWords[0].word).toBe('shepherd');

        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(4);
      });

      it('handles multiple scattered omissions correctly', () => {
        // "For so loved world" instead of "For God so loved the world"
        const actualWords = ['for', 'god', 'so', 'loved', 'the', 'world'];
        const spokenWords = ['for', 'so', 'loved', 'world'];
        const result = compareVersesLCS(spokenWords, actualWords);

        const missingWords = result.filter(r => r.status === 'missing');
        expect(missingWords.length).toBe(2);

        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(4);
      });

      it('handles insertion without cascading errors', () => {
        // "For um God so loved the world" instead of "For God so loved the world"
        const actualWords = ['for', 'god', 'so', 'loved', 'the', 'world'];
        const spokenWords = ['for', 'um', 'god', 'so', 'loved', 'the', 'world'];
        const result = compareVersesLCS(spokenWords, actualWords);

        const extraWords = result.filter(r => r.status === 'extra');
        expect(extraWords.length).toBe(1);
        expect(extraWords[0].word).toBe('um');

        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(6);
      });

      it('handles both insertion and omission in same verse', () => {
        // "For um so loved world" instead of "For God so loved the world"
        const actualWords = ['for', 'god', 'so', 'loved', 'the', 'world'];
        const spokenWords = ['for', 'um', 'so', 'loved', 'world'];
        const result = compareVersesLCS(spokenWords, actualWords);

        const extraWords = result.filter(r => r.status === 'extra');
        expect(extraWords.length).toBe(1);
        expect(extraWords[0].word).toBe('um');

        const missingWords = result.filter(r => r.status === 'missing');
        expect(missingWords.length).toBe(2);

        const correctWords = result.filter(r => r.status === 'correct');
        expect(correctWords.length).toBe(4);
      });
    });

    // ==========================================
    // Apostrophe handling with LCS
    // ==========================================

    it('matches "gods" to "God\'s" as correct', () => {
      const spokenWords = ['gods', 'love'];
      const actualWords = ["god's", 'love'];
      const result = compareVersesLCS(spokenWords, actualWords);

      expect(result[0]).toEqual({ word: 'gods', status: 'correct' });
      expect(result[1]).toEqual({ word: 'love', status: 'correct' });
    });
  });

  describe('compareVersesWithLCS', () => {
    it('identifies substitutions (extra followed by missing)', () => {
      // User says "lrod" instead of "lord"
      const spokenWords = ['the', 'lrod', 'is'];
      const actualWords = ['the', 'lord', 'is'];
      const result = compareVersesWithLCS(spokenWords, actualWords);

      // 'lrod' should be marked as wrong with expected 'lord'
      const wrongWords = result.filter(r => r.status === 'wrong');
      expect(wrongWords.length).toBe(1);
      expect(wrongWords[0].word).toBe('lrod');
      expect(wrongWords[0].expected).toBe('lord');

      const correctWords = result.filter(r => r.status === 'correct');
      expect(correctWords.length).toBe(2);
    });

    it('does not create false substitutions for distant mismatches', () => {
      // When 'um' is inserted and 'is' is missing, they shouldn't be treated as substitution
      // because there's a 'lord' (correct) between them
      const spokenWords = ['the', 'um', 'lord', 'my', 'shepherd'];
      const actualWords = ['the', 'lord', 'is', 'my', 'shepherd'];
      const result = compareVersesWithLCS(spokenWords, actualWords);

      // 'um' is extra, 'is' is missing - not a substitution because 'lord' is between
      const extraWords = result.filter(r => r.status === 'extra');
      expect(extraWords.length).toBe(1);

      const missingWords = result.filter(r => r.status === 'missing');
      expect(missingWords.length).toBe(1);
    });

    it('handles Romans 12:1 "and sisters" omission correctly', () => {
      // Same test as LCS but ensures substitution detection doesn't break it
      const actualWords = [
        'therefore', 'i', 'urge', 'you', 'brothers', 'and', 'sisters',
        'in', 'view', 'of', 'gods', 'mercy'
      ];
      const spokenWords = [
        'therefore', 'i', 'urge', 'you', 'brothers',
        'in', 'view', 'of', 'gods', 'mercy'
      ];
      const result = compareVersesWithLCS(spokenWords, actualWords);

      // Should identify exactly 2 missing words
      const missingWords = result.filter(r => r.status === 'missing');
      expect(missingWords.length).toBe(2);

      // All other words should be correct
      const correctWords = result.filter(r => r.status === 'correct');
      expect(correctWords.length).toBe(10);

      // No substitutions
      const wrongWords = result.filter(r => r.status === 'wrong');
      expect(wrongWords.length).toBe(0);
    });

    it('handles combination of omission and substitution', () => {
      // "For lrod loved world" instead of "For God so loved the world"
      // 'lrod' substitutes for something, 'so' and 'the' are missing
      const actualWords = ['for', 'god', 'so', 'loved', 'the', 'world'];
      const spokenWords = ['for', 'lrod', 'loved', 'world'];
      const result = compareVersesWithLCS(spokenWords, actualWords);

      // 'for', 'loved', 'world' should be correct
      const correctWords = result.filter(r => r.status === 'correct');
      expect(correctWords.length).toBe(3);

      // Should have some wrong or missing words
      const wrongAndMissing = result.filter(r => r.status === 'wrong' || r.status === 'missing');
      expect(wrongAndMissing.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('calculateAccuracy', () => {
    it('calculates 100% accuracy when all correct', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' }
      ];
      expect(calculateAccuracy(comparisonResult, 3)).toBe(100);
    });

    it('calculates 0% accuracy when all wrong', () => {
      const comparisonResult = [
        { word: 'foo', status: 'wrong', expected: 'the' },
        { word: 'bar', status: 'wrong', expected: 'lord' },
        { word: 'baz', status: 'wrong', expected: 'is' }
      ];
      expect(calculateAccuracy(comparisonResult, 3)).toBe(0);
    });

    it('calculates 0% accuracy when all missing', () => {
      const comparisonResult = [
        { word: 'the', status: 'missing' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'missing' }
      ];
      expect(calculateAccuracy(comparisonResult, 3)).toBe(0);
    });

    it('calculates partial accuracy correctly', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'correct' }
      ];
      expect(calculateAccuracy(comparisonResult, 4)).toBe(75);
    });

    it('ignores extra words in accuracy calculation', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'um', status: 'extra' },
        { word: 'lord', status: 'correct' }
      ];
      expect(calculateAccuracy(comparisonResult, 2)).toBe(100);
    });

    it('rounds accuracy to two decimal places', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'foo', status: 'wrong', expected: 'is' }
      ];
      // 2/3 = 66.666...% rounds to 66.67 (2 decimal places)
      expect(calculateAccuracy(comparisonResult, 3)).toBe(66.67);
    });

    it('handles edge case of 0 expected words', () => {
      const comparisonResult = [
        { word: 'the', status: 'extra' },
        { word: 'lord', status: 'extra' }
      ];
      expect(calculateAccuracy(comparisonResult, 0)).toBe(0);
    });

    it('calculates accuracy with mix of correct, wrong, and missing', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'missing' },
        { word: 'my', status: 'correct' },
        { word: 'shepherd', status: 'correct' }
      ];
      // 3 correct out of 5 total = 60%
      expect(calculateAccuracy(comparisonResult, 5)).toBe(60);
    });
  });

  describe('getSuggestedRating', () => {
    // Test range: 95-100% → 5
    it('suggests rating 5 for 100% accuracy', () => {
      expect(getSuggestedRating(100)).toBe(5);
    });

    it('suggests rating 5 for 95% accuracy (boundary)', () => {
      expect(getSuggestedRating(95)).toBe(5);
    });

    it('suggests rating 5 for 97% accuracy', () => {
      expect(getSuggestedRating(97)).toBe(5);
    });

    // Test range: 85-94% → 4
    it('suggests rating 4 for 94% accuracy (boundary)', () => {
      expect(getSuggestedRating(94)).toBe(4);
    });

    it('suggests rating 4 for 85% accuracy (boundary)', () => {
      expect(getSuggestedRating(85)).toBe(4);
    });

    it('suggests rating 4 for 90% accuracy', () => {
      expect(getSuggestedRating(90)).toBe(4);
    });

    // Test range: 70-84% → 3
    it('suggests rating 3 for 84% accuracy (boundary)', () => {
      expect(getSuggestedRating(84)).toBe(3);
    });

    it('suggests rating 3 for 70% accuracy (boundary)', () => {
      expect(getSuggestedRating(70)).toBe(3);
    });

    it('suggests rating 3 for 77% accuracy', () => {
      expect(getSuggestedRating(77)).toBe(3);
    });

    // Test range: 50-69% → 2
    it('suggests rating 2 for 69% accuracy (boundary)', () => {
      expect(getSuggestedRating(69)).toBe(2);
    });

    it('suggests rating 2 for 50% accuracy (boundary)', () => {
      expect(getSuggestedRating(50)).toBe(2);
    });

    it('suggests rating 2 for 60% accuracy', () => {
      expect(getSuggestedRating(60)).toBe(2);
    });

    // Test range: 0-49% → 1
    it('suggests rating 1 for 49% accuracy (boundary)', () => {
      expect(getSuggestedRating(49)).toBe(1);
    });

    it('suggests rating 1 for 0% accuracy', () => {
      expect(getSuggestedRating(0)).toBe(1);
    });

    it('suggests rating 1 for 25% accuracy', () => {
      expect(getSuggestedRating(25)).toBe(1);
    });

    // Additional edge cases
    it('handles decimal accuracy values', () => {
      expect(getSuggestedRating(94.5)).toBe(4);
      expect(getSuggestedRating(95.5)).toBe(5);
    });
  });

  describe('renderComparison', () => {
    it('renders correct words with word-correct class', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' }
      ];
      const html = renderComparison(comparisonResult);

      expect(html).toContain('<span class="word-correct">the</span>');
      expect(html).toContain('<span class="word-correct">lord</span>');
    });

    it('renders wrong words with word-wrong class and expected word', () => {
      const comparisonResult = [
        { word: 'lrod', status: 'wrong', expected: 'lord' }
      ];
      const html = renderComparison(comparisonResult);

      expect(html).toContain('<span class="word-wrong">lrod</span>');
      expect(html).toContain('<span class="word-expected">lord</span>');
    });

    it('renders missing words with word-missing class', () => {
      const comparisonResult = [
        { word: 'is', status: 'missing' }
      ];
      const html = renderComparison(comparisonResult);

      expect(html).toContain('<span class="word-missing">is</span>');
    });

    it('renders extra words with word-extra class', () => {
      const comparisonResult = [
        { word: 'um', status: 'extra' }
      ];
      const html = renderComparison(comparisonResult);

      expect(html).toContain('<span class="word-extra">um</span>');
    });

    it('renders mixed results correctly', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'missing' },
        { word: 'um', status: 'extra' },
        { word: 'my', status: 'correct' }
      ];
      const html = renderComparison(comparisonResult);

      expect(html).toContain('<span class="word-correct">the</span>');
      expect(html).toContain('<span class="word-wrong">lrod</span>');
      expect(html).toContain('<span class="word-expected">lord</span>');
      expect(html).toContain('<span class="word-missing">is</span>');
      expect(html).toContain('<span class="word-extra">um</span>');
      expect(html).toContain('<span class="word-correct">my</span>');
    });

    it('includes spaces between words', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' }
      ];
      const html = renderComparison(comparisonResult);

      // Should have space between words
      expect(html).toContain('</span> <span');
    });

    it('handles empty comparison result', () => {
      const comparisonResult = [];
      const html = renderComparison(comparisonResult);

      expect(html).toBe('');
    });

    it('places expected word after wrong word with proper spacing', () => {
      const comparisonResult = [
        { word: 'foo', status: 'wrong', expected: 'bar' }
      ];
      const html = renderComparison(comparisonResult);

      // Expected word should come after wrong word
      const wrongIndex = html.indexOf('word-wrong');
      const expectedIndex = html.indexOf('word-expected');
      expect(expectedIndex).toBeGreaterThan(wrongIndex);
    });

    it('renders real-world comparison example', () => {
      const comparisonResult = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' },
        { word: 'the', status: 'missing' },
        { word: 'world', status: 'correct' },
        { word: 'um', status: 'extra' },
        { word: 'that', status: 'correct' }
      ];
      const html = renderComparison(comparisonResult);

      expect(html).toContain('word-correct');
      expect(html).toContain('word-missing');
      expect(html).toContain('word-extra');
      expect(html.match(/word-correct/g)).toHaveLength(6);
    });
  });

  describe('renderComparisonHighlightOnly', () => {
    it('renders correct words with word-correct class', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      expect(html).toContain('<span class="word-correct">the</span>');
      expect(html).toContain('<span class="word-correct">lord</span>');
    });

    it('renders wrong words with word-error class (no expected word)', () => {
      const comparisonResult = [
        { word: 'lrod', status: 'wrong', expected: 'lord' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      expect(html).toContain('<span class="word-error">lrod</span>');
      expect(html).not.toContain('word-expected');
      expect(html).not.toContain('lord');
    });

    it('renders extra words with word-error class', () => {
      const comparisonResult = [
        { word: 'um', status: 'extra' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      expect(html).toContain('<span class="word-error">um</span>');
    });

    it('filters out missing words entirely', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'correct' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      expect(html).toContain('the');
      expect(html).toContain('is');
      expect(html).not.toContain('lord');
      expect(html).not.toContain('word-missing');
    });

    it('handles empty comparison result', () => {
      const html = renderComparisonHighlightOnly([]);
      expect(html).toBe('');
    });

    it('handles null input', () => {
      const html = renderComparisonHighlightOnly(null);
      expect(html).toBe('');
    });

    it('renders mixed results with simplified highlighting', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'missing' },
        { word: 'um', status: 'extra' },
        { word: 'my', status: 'correct' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      // Should have correct words
      expect(html).toContain('<span class="word-correct">the</span>');
      expect(html).toContain('<span class="word-correct">my</span>');
      // Should have error words (wrong and extra)
      expect(html).toContain('<span class="word-error">lrod</span>');
      expect(html).toContain('<span class="word-error">um</span>');
      // Should NOT have missing word or corrections
      expect(html).not.toContain('is');
      expect(html).not.toContain('lord');
      expect(html).not.toContain('word-missing');
      expect(html).not.toContain('word-expected');
    });

    it('includes spaces between words', () => {
      const comparisonResult = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      expect(html).toContain('</span> <span');
    });

    it('uses word-error for both wrong and extra (consistent highlighting)', () => {
      const comparisonResult = [
        { word: 'wrong-word', status: 'wrong', expected: 'correct-word' },
        { word: 'extra-word', status: 'extra' }
      ];
      const html = renderComparisonHighlightOnly(comparisonResult);

      // Both should use the same error class
      expect(html.match(/word-error/g)).toHaveLength(2);
    });
  });

  describe('filterTrailingMissing', () => {
    // ==========================================
    // Basic scenarios
    // ==========================================

    it('returns empty array for empty input', () => {
      expect(filterTrailingMissing([])).toEqual([]);
    });

    it('returns empty array for null input', () => {
      expect(filterTrailingMissing(null)).toEqual([]);
    });

    it('returns empty array for undefined input', () => {
      expect(filterTrailingMissing(undefined)).toEqual([]);
    });

    it('returns all words when no missing words present', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('returns all words when only correct words present', () => {
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    // ==========================================
    // Trailing missing words - should be removed
    // ==========================================

    it('removes single trailing missing word', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'missing' }
      ];
      const expected = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('removes multiple trailing missing words', () => {
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'missing' },
        { word: 'loved', status: 'missing' },
        { word: 'the', status: 'missing' },
        { word: 'world', status: 'missing' }
      ];
      const expected = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('removes many trailing missing words from long verse', () => {
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' },
        { word: 'the', status: 'missing' },
        { word: 'world', status: 'missing' },
        { word: 'that', status: 'missing' },
        { word: 'he', status: 'missing' },
        { word: 'gave', status: 'missing' },
        { word: 'his', status: 'missing' },
        { word: 'one', status: 'missing' },
        { word: 'and', status: 'missing' },
        { word: 'only', status: 'missing' },
        { word: 'son', status: 'missing' }
      ];
      const expected = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    // ==========================================
    // Missing words in the middle - should be kept
    // ==========================================

    it('keeps single missing word in the middle', () => {
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'missing' },
        { word: 'loved', status: 'correct' }
      ];
      // All words kept because 'loved' (correct) comes after 'so' (missing)
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('keeps multiple missing words in the middle', () => {
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'missing' },
        { word: 'so', status: 'missing' },
        { word: 'loved', status: 'correct' },
        { word: 'the', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('keeps missing word at the start when followed by spoken words', () => {
      const input = [
        { word: 'the', status: 'missing' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    // ==========================================
    // Mixed scenarios - middle missing kept, trailing missing removed
    // ==========================================

    it('keeps middle missing but removes trailing missing', () => {
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'missing' },  // skipped - should be kept
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' },
        { word: 'the', status: 'missing' },  // trailing - should be removed
        { word: 'world', status: 'missing' } // trailing - should be removed
      ];
      const expected = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'missing' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('handles complex scenario with multiple gaps', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'missing' },  // skipped - keep
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'missing' },    // skipped - keep
        { word: 'shepherd', status: 'correct' },
        { word: 'i', status: 'missing' },     // trailing - remove
        { word: 'shall', status: 'missing' }, // trailing - remove
        { word: 'not', status: 'missing' },   // trailing - remove
        { word: 'want', status: 'missing' }   // trailing - remove
      ];
      const expected = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'missing' },
        { word: 'shepherd', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    // ==========================================
    // Wrong words - should anchor the end
    // ==========================================

    it('keeps trailing missing when wrong word comes after', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'iz', status: 'wrong', expected: 'is' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('removes trailing missing after wrong word', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'missing' },
        { word: 'my', status: 'missing' }
      ];
      const expected = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('wrong word at the end anchors the result', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'missing' },
        { word: 'mie', status: 'wrong', expected: 'my' }
      ];
      // 'is' (missing) comes before 'mie' (wrong), so 'is' is kept
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    // ==========================================
    // Extra words - should anchor the end
    // ==========================================

    it('keeps all words when extra word is at the end', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'um', status: 'extra' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('removes trailing missing after extra word', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'um', status: 'extra' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'missing' }
      ];
      const expected = [
        { word: 'the', status: 'correct' },
        { word: 'um', status: 'extra' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('extra word in middle followed by correct word keeps missing between them', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'um', status: 'extra' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    // ==========================================
    // Edge cases
    // ==========================================

    it('returns empty array when all words are missing', () => {
      const input = [
        { word: 'the', status: 'missing' },
        { word: 'lord', status: 'missing' },
        { word: 'is', status: 'missing' }
      ];
      expect(filterTrailingMissing(input)).toEqual([]);
    });

    it('handles single correct word', () => {
      const input = [
        { word: 'the', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('handles single missing word (returns empty)', () => {
      const input = [
        { word: 'the', status: 'missing' }
      ];
      expect(filterTrailingMissing(input)).toEqual([]);
    });

    it('handles single wrong word', () => {
      const input = [
        { word: 'teh', status: 'wrong', expected: 'the' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('handles single extra word', () => {
      const input = [
        { word: 'um', status: 'extra' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    // ==========================================
    // Real-world scenarios
    // ==========================================

    it('handles John 3:16 partial recitation', () => {
      // User says: "For God so loved the world"
      // Actual: "For God so loved the world that he gave his one and only Son"
      const input = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' },
        { word: 'the', status: 'correct' },
        { word: 'world', status: 'correct' },
        { word: 'that', status: 'missing' },
        { word: 'he', status: 'missing' },
        { word: 'gave', status: 'missing' },
        { word: 'his', status: 'missing' },
        { word: 'one', status: 'missing' },
        { word: 'and', status: 'missing' },
        { word: 'only', status: 'missing' },
        { word: 'son', status: 'missing' }
      ];
      const expected = [
        { word: 'for', status: 'correct' },
        { word: 'god', status: 'correct' },
        { word: 'so', status: 'correct' },
        { word: 'loved', status: 'correct' },
        { word: 'the', status: 'correct' },
        { word: 'world', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('handles Psalm 23:1 with skipped word', () => {
      // User says: "The Lord is shepherd" (skipped "my")
      // Actual: "The Lord is my shepherd"
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'missing' },
        { word: 'shepherd', status: 'correct' }
      ];
      // All kept because 'shepherd' (correct) comes after 'my' (missing)
      expect(filterTrailingMissing(input)).toEqual(input);
    });

    it('handles recitation with hesitation words', () => {
      // User says: "The um Lord is"
      // Actual: "The Lord is my shepherd"
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'um', status: 'extra' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'missing' },
        { word: 'shepherd', status: 'missing' }
      ];
      const expected = [
        { word: 'the', status: 'correct' },
        { word: 'um', status: 'extra' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('handles recitation with wrong word and skipped words', () => {
      // User says: "The Lrod is my" (misspelled Lord, partial verse)
      // Actual: "The Lord is my shepherd I shall not want"
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'correct' },
        { word: 'shepherd', status: 'missing' },
        { word: 'i', status: 'missing' },
        { word: 'shall', status: 'missing' },
        { word: 'not', status: 'missing' },
        { word: 'want', status: 'missing' }
      ];
      const expected = [
        { word: 'the', status: 'correct' },
        { word: 'lrod', status: 'wrong', expected: 'lord' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(expected);
    });

    it('handles complete correct recitation (no filtering needed)', () => {
      const input = [
        { word: 'the', status: 'correct' },
        { word: 'lord', status: 'correct' },
        { word: 'is', status: 'correct' },
        { word: 'my', status: 'correct' },
        { word: 'shepherd', status: 'correct' }
      ];
      expect(filterTrailingMissing(input)).toEqual(input);
    });
  });
});
