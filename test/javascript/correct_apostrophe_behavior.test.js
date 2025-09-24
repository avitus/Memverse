import { describe, it, expect } from 'vitest';
import { memverseLib } from './helpers.js';

describe("Correct Apostrophe Handling Behavior", () => {
  describe("flexibleTextMatch - What SHOULD and SHOULD NOT match", () => {
    it("should require complete words - no base word matching", () => {
      // Base words should NOT match possessives
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(false);
      expect(memverseLib.flexibleTextMatch("children's", "children")).toBe(false);
      expect(memverseLib.flexibleTextMatch("Lord's", "Lord")).toBe(false);

      // Base words should NOT match contractions
      expect(memverseLib.flexibleTextMatch("don't", "don")).toBe(false);
      expect(memverseLib.flexibleTextMatch("can't", "can")).toBe(false);
      expect(memverseLib.flexibleTextMatch("won't", "won")).toBe(false);
    });

    it("should accept exact matches", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor's")).toBe(true);
      expect(memverseLib.flexibleTextMatch("don't", "don't")).toBe(true);
      expect(memverseLib.flexibleTextMatch("the", "the")).toBe(true);
    });

    it("should accept matches without apostrophes (complete word)", () => {
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
      expect(memverseLib.flexibleTextMatch("children's", "childrens")).toBe(true);
      expect(memverseLib.flexibleTextMatch("don't", "dont")).toBe(true);
    });

    it("should handle quotation marks at beginning", () => {
      expect(memverseLib.flexibleTextMatch('"The', "The")).toBe(true);
      expect(memverseLib.flexibleTextMatch("'The", "The")).toBe(true);
    });
  });

  describe("User typing experience", () => {
    it("demonstrates correct typing flow for neighbor's", () => {
      const word = "neighbor's";

      // As user types, no match until complete
      expect(memverseLib.flexibleTextMatch(word, "n")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "ne")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "nei")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neig")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neigh")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighb")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbo")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbor")).toBe(false); // NOT a match
      expect(memverseLib.flexibleTextMatch(word, "neighbor'")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbor's")).toBe(true); // Complete match

      // Alternative: type without apostrophe
      expect(memverseLib.flexibleTextMatch(word, "neighbors")).toBe(true); // Also complete
    });
  });

  describe("Exodus 20:17 specific behavior", () => {
    it("requires complete word for all three instances of neighbor's", () => {
      const word = "neighbor's";

      // Must type complete word
      expect(memverseLib.flexibleTextMatch(word, "neighbor")).toBe(false);
      expect(memverseLib.flexibleTextMatch(word, "neighbor's")).toBe(true);
      expect(memverseLib.flexibleTextMatch(word, "neighbors")).toBe(true);
    });

    it("handles the final word with punctuation correctly", () => {
      const finalWord = 'neighbor\'s."';

      // Still requires complete word
      expect(memverseLib.flexibleTextMatch(finalWord, "neighbor")).toBe(false);

      // This actually matches because scrub_text removes punctuation
      // and "neighbors" scrubbed equals "neighbor's" scrubbed
      expect(memverseLib.flexibleTextMatch(finalWord, "neighbors")).toBe(true);

      // These should work with scrub_text
      const scrubbed = memverseLib.scrub_text(finalWord);
      expect(scrubbed).toBe("neighbors");
    });
  });

  describe("No premature completion", () => {
    it("should not complete prematurely on any partial match", () => {
      // Possessives
      expect(memverseLib.flexibleTextMatch("neighbor's", "neighbor")).toBe(false);
      expect(memverseLib.flexibleTextMatch("children's", "children")).toBe(false);

      // Contractions
      expect(memverseLib.flexibleTextMatch("don't", "don")).toBe(false);
      expect(memverseLib.flexibleTextMatch("can't", "can")).toBe(false);

      // This prevents the frustrating experience of premature field advancement
    });
  });
});