import { describe, it, expect, beforeEach } from 'vitest';
import { memverseLib } from './helpers.js';

describe("Exodus 20:17 Final Word Special Case", () => {
  beforeEach(() => {
    document.body.innerHTML = '<div class="passage-text"></div>';
  });

  describe("Final word with apostrophe and closing punctuation", () => {
    it("should identify the exact final word from Exodus 20:17", () => {
      const verseText = '"You shall not covet your neighbor\'s house; you shall not covet your neighbor\'s wife, or his male servant, or his female servant, or his ox, or his donkey, or anything that is your neighbor\'s."';

      // The last word before the closing punctuation
      const words = verseText.split(/\s+/);
      const lastWord = words[words.length - 1];

      expect(lastWord).toBe('neighbor\'s."');

      // When blankified, the word name will be just the word without quotes/periods
      // Let's check what blankify does
      const blankified = memverseLib.blankifyVerse(verseText, 100);
      console.log("Last portion of blankified:", blankified.slice(-200));
    });

    it("should test matching for 'neighbor\\'s.' with period", () => {
      // The word might appear in the input as "neighbor's." (with period)
      const variations = [
        { correct: "neighbor's.", userInput: "neighbor", shouldMatch: false }, // Base word not accepted
        { correct: "neighbor's.", userInput: "neighbors", shouldMatch: true },  // Apostrophe removed works
        { correct: "neighbor's.", userInput: "neighbor's", shouldMatch: true }, // Without period works
        { correct: "neighbor's.", userInput: "neighbor's.", shouldMatch: true }, // Exact match works
      ];

      variations.forEach(test => {
        const result = memverseLib.flexibleTextMatch(test.correct, test.userInput);
        console.log(`Testing "${test.correct}" vs "${test.userInput}": ${result}`);
        expect(result).toBe(test.shouldMatch);
      });
    });

    it('should test matching for neighbor\'s." with quotes and period', () => {
      // The full word as it appears at the end
      const variations = [
        { correct: 'neighbor\'s."', userInput: "neighbor", shouldMatch: false }, // Base word not accepted
        { correct: 'neighbor\'s."', userInput: "neighbors", shouldMatch: true },  // Apostrophe removed works
        { correct: 'neighbor\'s."', userInput: "neighbor's", shouldMatch: true }, // Without quotes/period works
        { correct: 'neighbor\'s."', userInput: 'neighbor\'s."', shouldMatch: true }, // Exact match works
      ];

      variations.forEach(test => {
        const result = memverseLib.flexibleTextMatch(test.correct, test.userInput);
        console.log(`Testing "${test.correct}" vs "${test.userInput}": ${result}`);
        expect(result).toBe(test.shouldMatch);
      });
    });

    it("should check how blankify handles the final word", () => {
      // Test just the final portion
      const endText = "anything that is your neighbor's.";
      const blankified = memverseLib.blankifyVerse(endText, 100);

      // Check if the input name attribute is properly escaped
      expect(blankified).toContain("neighbor");

      // Log to see exact structure
      console.log("Blankified end text:", blankified);

      // Parse to find the actual input name
      const match = blankified.match(/name='([^']+)'/);
      if (match) {
        console.log("Input name attribute:", match[1]);

        // Test matching with the actual name attribute
        const inputName = match[1];
        expect(memverseLib.flexibleTextMatch(inputName, "neighbor")).toBe(true);
        expect(memverseLib.flexibleTextMatch(inputName, "neighbors")).toBe(true);
      }
    });

    it("should handle punctuation in scrub_text", () => {
      // Check what scrub_text does with punctuation
      expect(memverseLib.scrub_text("neighbor's.")).toBe("neighbors");
      expect(memverseLib.scrub_text('neighbor\'s."')).toBe("neighbors");
      expect(memverseLib.scrub_text("neighbor")).toBe("neighbor");

      // This might be why it's not matching - the period is being removed
    });
  });

  describe("Real-world passage review scenario", () => {
    it("should handle the complete Exodus 20:17 verse", () => {
      const verseText = '"You shall not covet your neighbor\'s house; you shall not covet your neighbor\'s wife, or his male servant, or his female servant, or his ox, or his donkey, or anything that is your neighbor\'s."';

      // Blankify at high percentage to get all neighbor's instances
      const blankified = memverseLib.blankifyVerse(verseText, 50);
      document.querySelector('.passage-text').innerHTML = blankified;

      // Find all inputs with "neighbor" in the name
      const inputs = document.querySelectorAll('input[name*="neighbor"]');
      console.log(`Found ${inputs.length} inputs with 'neighbor' in name`);

      inputs.forEach((input, index) => {
        console.log(`Input ${index + 1} name: "${input.name}"`);

        // User types "neighbor" for each
        const matches = memverseLib.flexibleTextMatch(input.name, "neighbor");
        console.log(`  Matches with "neighbor": ${matches}`);
      });
    });
  });
});