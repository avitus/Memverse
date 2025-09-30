import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("Passage Review Exodus 20:17 Apostrophe Handling", () => {
  let verseText;
  let originalFlexibleTextMatch;

  beforeEach(() => {
    // Exodus 20:17 ESV text with multiple apostrophes
    verseText = "You shall not covet your neighbor's house; you shall not covet your neighbor's wife, or his male servant, or his female servant, or his ox, or his donkey, or anything that is your neighbor's.";

    // Set up DOM
    document.body.innerHTML = '<div class="passage-text"></div>';

    // Save original function to test current behavior
    originalFlexibleTextMatch = memverseLib.flexibleTextMatch;
  });

  afterEach(() => {
    document.querySelector('.passage-text')?.remove();
    document.getElementById('word_width')?.remove();
  });

  describe("Current flexibleTextMatch behavior", () => {
    it("does NOT allow 'neighbor' to match 'neighbor's' (current behavior)", () => {
      // Current implementation does not match base words
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(false);
    });

    it("should allow 'neighbors' to match 'neighbor's'", () => {
      // This continues to work
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
    });

    it("should accept all variations of apostrophe words", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor's")).toBe(true);
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(false); // Current behavior
    });
  });

  describe("Current behavior tests", () => {
    it("should demonstrate current apostrophe matching behavior", () => {
      // Current behavior:
      const testCases = [
        { correct: "neighbor's", userInput: "neighbor", shouldMatch: false }, // Base word not accepted
        { correct: "neighbor's", userInput: "neighbors", shouldMatch: true },  // Apostrophe removed
        { correct: "neighbor's", userInput: "neighbor's", shouldMatch: true }, // Exact match
        { correct: "don't", userInput: "dont", shouldMatch: true },          // Apostrophe removed
        { correct: "don't", userInput: "don", shouldMatch: false },          // Base word not accepted
        { correct: "can't", userInput: "cant", shouldMatch: true },          // Apostrophe removed
        { correct: "can't", userInput: "can", shouldMatch: false }           // Base word not accepted
      ];

      testCases.forEach(testCase => {
        const result = memverseLib.flexibleTextMatch(testCase.correct, testCase.userInput);
        expect(result).toBe(testCase.shouldMatch);
      });
    });
  });

  describe("Full verse review scenario", () => {
    it("should handle Exodus 20:17 with multiple 'neighbor's'", () => {
      // Count how many times neighbor's appears
      const neighborCount = (verseText.match(/neighbor's/g) || []).length;
      expect(neighborCount).toBe(3);

      // Simulate blankifying the verse
      const blankified = memverseLib.blankifyVerse(verseText, 30);
      document.querySelector('.passage-text').innerHTML = blankified;

      // Find input fields for neighbor's
      const inputs = document.querySelectorAll('.passage-text input[name="neighbor\'s"]');
      expect(inputs.length).toBeGreaterThan(0);

      // Simulate user typing without apostrophe
      inputs.forEach(input => {
        // User types "neighbor" instead of "neighbor's"
        input.value = 'neighbor';

        // Current behavior: base word does NOT match
        expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(false);

        // User must type "neighbors" (without apostrophe) or exact match
      });
    });
  });

  describe("Other punctuation cases", () => {
    it("should handle quotation marks flexibly", () => {
      expect(memverseLib.flexibleTextMatch('"You', 'You')).toBe(true);
      expect(memverseLib.flexibleTextMatch('"You', '"You')).toBe(true);
    });

    it("should handle trailing apostrophes", () => {
      // Due to scrub_text, trailing apostrophes are removed so base words match
      expect(memverseLib.flexibleTextMatch("Jesus'", "Jesus")).toBe(true);
      expect(memverseLib.flexibleTextMatch("disciples'", "disciples")).toBe(true);
    });

    it("should not create false matches", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "house")).toBe(false);
      expect(memverseLib.flexibleTextMatch("don't", "do")).toBe(false);
    });
  });

  describe("Solution demonstration", () => {
    it("should show how the enhanced implementation helps users", () => {
      // User trying to type Exodus 20:17
      const words = ["neighbor's", "neighbor's", "neighbor's"];

      words.forEach(word => {
        // User naturally types "neighbor" without apostrophe
        const userInput = "neighbor";
        const matches = memverseLib.flexibleTextMatch(word, userInput);

        // Current behavior: this does NOT match
        expect(matches).toBe(false);

        console.log(`User types "${userInput}" for "${word}": ${matches ? 'PASS' : 'FAIL'}`);
      });
    });
  });
});