import { describe, it, expect } from 'vitest';
import { memverseLib } from './helpers.js';

describe("Final Solution for Apostrophe Handling", () => {
  describe("flexibleTextMatch (auto-advance)", () => {
    it("should accept exact matches without space", () => {
      expect(memverseLib.flexibleTextMatch("the", "the")).toBe(true);
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor's")).toBe(true);
      expect(memverseLib.flexibleTextMatch("God", "God")).toBe(true);
    });

    it("should accept close matches without space", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
      expect(memverseLib.flexibleTextMatch("don't", "dont")).toBe(true);
      expect(memverseLib.flexibleTextMatch("children's", "childrens")).toBe(true);
    });

    it("should NOT accept base words (prevents premature completion)", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(false);
      expect(memverseLib.flexibleTextMatch("children's", "children")).toBe(false);
      expect(memverseLib.flexibleTextMatch("don't", "don")).toBe(false);
    });
  });

  describe("flexibleTextMatchWithBase (space-triggered)", () => {
    it("should accept everything flexibleTextMatch accepts", () => {
      expect(memverseLib.flexibleTextMatchWithBase("the", "the")).toBe(true);
      expect(memverseLib.flexibleTextMatchWithBase("neighbor's", "neighbors")).toBe(true);
      expect(memverseLib.flexibleTextMatchWithBase("don't", "dont")).toBe(true);
    });

    it("should ALSO accept base words (for space-triggered completion)", () => {
      expect(memverseLib.flexibleTextMatchWithBase("neighbor's", "neighbor")).toBe(true);
      expect(memverseLib.flexibleTextMatchWithBase("children's", "children")).toBe(true);
      expect(memverseLib.flexibleTextMatchWithBase("don't", "don")).toBe(true);
    });
  });

  describe("User Experience", () => {
    it("demonstrates the desired typing flow", () => {
      const word = "neighbor's";

      // As user types, auto-advance only on exact/close match
      expect(memverseLib.flexibleTextMatch(word, "n")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "ne")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "nei")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neig")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neigh")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighb")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbo")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbor")).toBe(false); // NO auto-advance
      expect(memverseLib.flexibleTextMatch(word, "neighbor'")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbor's")).toBe(true); // YES auto-advance

      // But with space, base word is accepted
      expect(memverseLib.flexibleTextMatchWithBase(word, "neighbor")).toBe(true);
    });
  });

  describe("Exodus 20:17 Specific Cases", () => {
    it("handles all three instances of neighbor's correctly", () => {
      const word = "neighbor's";

      // Without space - no match on base word
      expect(memverseLib.flexibleTextMatch(word, "neighbor")).toBe(false);

      // With space (using enhanced function) - match
      expect(memverseLib.flexibleTextMatchWithBase(word, "neighbor")).toBe(true);

      // Exact and close matches work without space
      expect(memverseLib.flexibleTextMatch(word, "neighbor's")).toBe(true);
      expect(memverseLib.flexibleTextMatch(word, "neighbors")).toBe(true);
    });

    it("handles the final word with punctuation", () => {
      const finalWord = "neighbor's.\"";

      // Base word doesn't auto-advance
      expect(memverseLib.flexibleTextMatch(finalWord, "neighbor")).toBe(false);

      // But works with space-triggered
      expect(memverseLib.flexibleTextMatchWithBase(finalWord, "neighbor")).toBe(true);
    });
  });
});