import { describe, it, expect } from 'vitest';
import { memverseLib } from './helpers.js';

const parseVerseRef = memverseLib.parseVerseRef;
const refTestState = memverseLib.refTestState;

describe("Reference Test Scoring", () => {

  describe("calcRefScore", () => {
    it("scores 10 for exact match", () => {
      var answer  = parseVerseRef("Revelation 22:21");
      var correct = parseVerseRef("Revelation 22:21");
      expect(refTestState.calcRefScore(answer, correct)).toBe(10);
    });

    it("scores 5 for correct book and chapter", () => {
      var answer  = parseVerseRef("Romans 8:1");
      var correct = parseVerseRef("Romans 8:28");
      expect(refTestState.calcRefScore(answer, correct)).toBe(5);
    });

    it("scores 1 for correct book only", () => {
      var answer  = parseVerseRef("Romans 1:1");
      var correct = parseVerseRef("Romans 8:28");
      expect(refTestState.calcRefScore(answer, correct)).toBe(1);
    });

    it("scores 0 for completely wrong reference", () => {
      var answer  = parseVerseRef("Genesis 1:1");
      var correct = parseVerseRef("Romans 8:28");
      expect(refTestState.calcRefScore(answer, correct)).toBe(0);
    });

    it("returns 0 when answerRef is false", () => {
      expect(refTestState.calcRefScore(false, parseVerseRef("Romans 8:28"))).toBe(0);
    });

    it("returns 0 when correctRef is false", () => {
      expect(refTestState.calcRefScore(parseVerseRef("Romans 8:28"), false)).toBe(0);
    });

    it("returns 0 when both are false", () => {
      expect(refTestState.calcRefScore(false, false)).toBe(0);
    });

    it("handles identical verses in different books", () => {
      // The actual bug scenario: Revelation 22:21 vs Philippians 4:23
      var answer  = parseVerseRef("Philippians 4:23");
      var primary = parseVerseRef("Revelation 22:21");
      var alternate = parseVerseRef("Philippians 4:23");

      // Primary doesn't match
      expect(refTestState.calcRefScore(answer, primary)).toBe(0);
      // But alternate does - this is the fix
      expect(refTestState.calcRefScore(answer, alternate)).toBe(10);
    });

    it("finds best score across multiple candidates", () => {
      // Simulates the scoreRef loop logic: check primary + all alternates, take max
      var answer = parseVerseRef("Psalms 107:31");
      var candidates = [
        parseVerseRef("Psalms 107:8"),   // primary: book+chapter match = 5
        parseVerseRef("Psalms 107:15"),  // alt: book+chapter match = 5
        parseVerseRef("Psalms 107:22"),  // alt: book+chapter match = 5
        parseVerseRef("Psalms 107:31"),  // alt: exact match = 10
      ];

      var bestScore = 0;
      for (var i = 0; i < candidates.length; i++) {
        var score = refTestState.calcRefScore(answer, candidates[i]);
        if (score > bestScore) bestScore = score;
      }
      expect(bestScore).toBe(10);
    });
  });
});
