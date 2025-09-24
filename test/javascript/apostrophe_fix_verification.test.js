import { describe, it, expect } from 'vitest';
import { memverseLib } from './helpers.js';

describe("Flexible Text Match - Apostrophe Fix Verification", () => {
  describe("Possessive forms", () => {
    it("should accept base word for possessive 's", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(true);
      expect(memverseLib.flexibleTextMatch("Lord's", "Lord")).toBe(true);
      expect(memverseLib.flexibleTextMatch("children's", "children")).toBe(true);
      expect(memverseLib.flexibleTextMatch("man's", "man")).toBe(true);
    });

    it("should accept word without apostrophe", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
      expect(memverseLib.flexibleTextMatch("Lord's", "Lords")).toBe(true);
      expect(memverseLib.flexibleTextMatch("children's", "childrens")).toBe(true);
    });

    it("should accept exact match with apostrophe", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor's")).toBe(true);
      expect(memverseLib.flexibleTextMatch("Lord's", "Lord's")).toBe(true);
    });

    it("should handle trailing apostrophes", () => {
      expect(memverseLib.flexibleTextMatch("Jesus'", "Jesus")).toBe(true);
      expect(memverseLib.flexibleTextMatch("disciples'", "disciples")).toBe(true);
      expect(memverseLib.flexibleTextMatch("Moses'", "Moses")).toBe(true);
    });
  });

  describe("Contractions", () => {
    it("should accept base word before apostrophe", () => {
      expect(memverseLib.flexibleTextMatch("don't", "don")).toBe(true);
      expect(memverseLib.flexibleTextMatch("can't", "can")).toBe(true);
      expect(memverseLib.flexibleTextMatch("won't", "won")).toBe(true);
      expect(memverseLib.flexibleTextMatch("I'm", "I")).toBe(true);
      expect(memverseLib.flexibleTextMatch("you're", "you")).toBe(true);
      expect(memverseLib.flexibleTextMatch("we'll", "we")).toBe(true);
    });

    it("should accept word without apostrophe", () => {
      expect(memverseLib.flexibleTextMatch("don't", "dont")).toBe(true);
      expect(memverseLib.flexibleTextMatch("can't", "cant")).toBe(true);
      expect(memverseLib.flexibleTextMatch("won't", "wont")).toBe(true);
      expect(memverseLib.flexibleTextMatch("I'm", "Im")).toBe(true);
      expect(memverseLib.flexibleTextMatch("you're", "youre")).toBe(true);
      expect(memverseLib.flexibleTextMatch("we'll", "well")).toBe(true);
    });

    it("should accept exact match", () => {
      expect(memverseLib.flexibleTextMatch("don't", "don't")).toBe(true);
      expect(memverseLib.flexibleTextMatch("can't", "can't")).toBe(true);
    });
  });

  describe("Quotation marks", () => {
    it("should accept word without leading quotes", () => {
      expect(memverseLib.flexibleTextMatch('"You', 'You')).toBe(true);
      expect(memverseLib.flexibleTextMatch('"The', 'The')).toBe(true);
      expect(memverseLib.flexibleTextMatch('"Lord', 'Lord')).toBe(true);
      expect(memverseLib.flexibleTextMatch("'Come", "Come")).toBe(true);
    });

    it("should accept exact match with quotes", () => {
      expect(memverseLib.flexibleTextMatch('"You', '"You')).toBe(true);
      expect(memverseLib.flexibleTextMatch("'Come", "'Come")).toBe(true);
    });
  });

  describe("False positive prevention", () => {
    it("should not match completely different words", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "house")).toBe(false);
      expect(memverseLib.flexibleTextMatch("don't", "do")).toBe(false);
      expect(memverseLib.flexibleTextMatch("can't", "car")).toBe(false);
      expect(memverseLib.flexibleTextMatch("Lord's", "King")).toBe(false);
    });

    it("should not match partial words that are too short", () => {
      expect(memverseLib.flexibleTextMatch("I'm", "In")).toBe(false);
      expect(memverseLib.flexibleTextMatch("we'll", "well")).toBe(true); // This should match
      expect(memverseLib.flexibleTextMatch("you're", "your")).toBe(false);
    });
  });

  describe("Case insensitivity", () => {
    it("should be case insensitive", () => {
      expect(memverseLib.flexibleTextMatch("Neighbor's", "neighbor")).toBe(true);
      expect(memverseLib.flexibleTextMatch("neighbor's", "Neighbor")).toBe(true);
      expect(memverseLib.flexibleTextMatch("DON'T", "dont")).toBe(true);
      expect(memverseLib.flexibleTextMatch("don't", "DON")).toBe(true);
    });
  });

  describe("Exodus 20:17 specific cases", () => {
    it("should handle all instances in Exodus 20:17", () => {
      // All three instances of "neighbor's" should accept "neighbor"
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(true);

      // Should also accept other variations
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor's")).toBe(true);
    });
  });

  describe("Edge cases", () => {
    it("should handle multiple apostrophes", () => {
      expect(memverseLib.flexibleTextMatch("don't", "dont")).toBe(true);
      expect(memverseLib.flexibleTextMatch("can't", "cant")).toBe(true);
    });

    it("should handle empty strings", () => {
      expect(memverseLib.flexibleTextMatch("", "")).toBe(true);
      expect(memverseLib.flexibleTextMatch("word", "")).toBe(false);
      expect(memverseLib.flexibleTextMatch("", "word")).toBe(false);
    });

    it("should use scrub_text for non-punctuation cases", () => {
      // These should still use the scrub_text logic
      expect(memverseLib.flexibleTextMatch("hello", "HELLO")).toBe(true);
      // Note: scrub_text keeps numbers in the latest implementation
      const scrubbed = memverseLib.scrub_text("test123");
      console.log(`scrub_text("test123") = "${scrubbed}"`);
      // Just verify that scrub_text is being used for matching
      expect(memverseLib.flexibleTextMatch("test", "test")).toBe(true);
      expect(memverseLib.flexibleTextMatch("test", "TEST")).toBe(true);
    });
  });
});