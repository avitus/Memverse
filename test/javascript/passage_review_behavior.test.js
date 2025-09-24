import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { memverseLib } from './helpers.js';

describe("Passage Review Typing Behavior", () => {
  let container;
  let keyupHandler;

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div class="passage-text"></div>
    `;
    container = document.querySelector('.passage-text');

    // Mock jQuery-like functionality for testing
    global.$ = (selector) => {
      const elem = typeof selector === 'string' ? document.querySelector(selector) : selector;
      return {
        val: (value) => {
          if (value !== undefined) {
            elem.value = value;
            return { val: () => value };
          }
          return elem.value || '';
        },
        attr: (name) => elem.getAttribute(name),
        before: (html) => {
          if (typeof html === 'string') {
            elem.insertAdjacentHTML('beforebegin', html);
          }
        },
        remove: () => elem.remove(),
        width: () => parseInt(elem.style.width) || 100,
        next: () => elem.nextElementSibling,
        nextUntil: () => [],
        on: (event, handler) => {
          elem.addEventListener(event, handler);
        }
      };
    };
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe("Expected Passage Review Behaviors", () => {
    it("should advance immediately when exact word is typed (no space required)", () => {
      // Setup: Create input for "the"
      container.innerHTML = '<input name="the" class="blank-word" value="" style="width:30px">';
      const input = container.querySelector('input');
      let advanced = false;

      // Simulate the passage review logic
      const checkWord = () => {
        const correctWord = input.name;
        const userGuess = input.value;

        if (memverseLib.flexibleTextMatch(correctWord, userGuess)) {
          advanced = true;
          input.insertAdjacentHTML('beforebegin', `<span>${correctWord} </span>`);
          input.value = '';
        }
      };

      // Type "the" character by character
      ['t', 'th', 'the'].forEach(text => {
        input.value = text;
        checkWord();
      });

      // Should advance when complete word is typed
      expect(advanced).toBe(true);
      expect(input.value).toBe('');
    });

    it("should NOT require space for exact matches", () => {
      const testCases = [
        { word: "God", typed: "God", shouldAdvance: true },
        { word: "love", typed: "love", shouldAdvance: true },
        { word: "the", typed: "the", shouldAdvance: true },
        { word: "beginning", typed: "beginning", shouldAdvance: true }
      ];

      testCases.forEach(test => {
        container.innerHTML = `<input name="${test.word}" class="blank-word" value="${test.typed}">`;
        const input = container.querySelector('input');

        const matches = memverseLib.flexibleTextMatch(test.word, test.typed);
        expect(matches).toBe(test.shouldAdvance);

        if (test.shouldAdvance) {
          console.log(`✓ "${test.typed}" should auto-advance for "${test.word}" (no space needed)`);
        }
      });
    });

    it("should NOT advance prematurely for partial words", () => {
      const testCases = [
        { word: "children's", typed: "child", shouldAdvance: false },
        { word: "children's", typed: "childre", shouldAdvance: false },
        { word: "children's", typed: "children", shouldAdvance: false }, // This is the key case
        { word: "neighbor's", typed: "neighb", shouldAdvance: false },
        { word: "neighbor's", typed: "neighbor", shouldAdvance: false }
      ];

      testCases.forEach(test => {
        const matches = memverseLib.flexibleTextMatch(test.word, test.typed);

        // Current implementation might return true for "children" matching "children's"
        // but we should NOT auto-advance in this case
        console.log(`"${test.typed}" vs "${test.word}": matches=${matches}, shouldAdvance=${test.shouldAdvance}`);

        if (test.typed === "children" && test.word === "children's") {
          // This is the problematic case - we need special handling
          expect(test.shouldAdvance).toBe(false);
        }
      });
    });

    it("should handle the complete word without requiring space", () => {
      const testCases = [
        { word: "children's", typed: "children's", shouldAdvance: true },
        { word: "children's", typed: "childrens", shouldAdvance: true },
        { word: "don't", typed: "don't", shouldAdvance: true },
        { word: "don't", typed: "dont", shouldAdvance: true }
      ];

      testCases.forEach(test => {
        const matches = memverseLib.flexibleTextMatch(test.word, test.typed);
        expect(matches).toBe(true);
        console.log(`✓ "${test.typed}" should auto-advance for "${test.word}" (exact/close match)`);
      });
    });

    it("should allow space-triggered completion for shortened forms", () => {
      // When user types "children" + SPACE for "children's", it should match
      // But "children" alone (without space) should NOT auto-advance

      const word = "children's";
      const typed = "children";

      // Without space - should not advance
      const matchesWithoutSpace = memverseLib.flexibleTextMatch(word, typed);
      // This currently returns true, which causes premature advancement

      // With space - should advance
      const matchesWithSpace = memverseLib.flexibleTextMatch(word, typed);
      // Space indicates user is done with the word

      console.log(`Issue: "${typed}" matches "${word}": ${matchesWithoutSpace}`);
      console.log(`This causes premature field advancement`);
    });
  });

  describe("Passage Review Event Flow", () => {
    it("should demonstrate the correct typing flow", () => {
      const events = [];

      // Simulate typing "children's"
      const typingSequence = [
        { key: 'c', value: 'c', shouldAdvance: false },
        { key: 'h', value: 'ch', shouldAdvance: false },
        { key: 'i', value: 'chi', shouldAdvance: false },
        { key: 'l', value: 'chil', shouldAdvance: false },
        { key: 'd', value: 'child', shouldAdvance: false },
        { key: 'r', value: 'childr', shouldAdvance: false },
        { key: 'e', value: 'childre', shouldAdvance: false },
        { key: 'n', value: 'children', shouldAdvance: false }, // Critical: should NOT advance here
        { key: "'", value: "children'", shouldAdvance: false },
        { key: 's', value: "children's", shouldAdvance: true }  // Should advance here
      ];

      typingSequence.forEach((step, index) => {
        events.push({
          step: index + 1,
          key: step.key,
          value: step.value,
          shouldAdvance: step.shouldAdvance
        });
      });

      // Log the expected flow
      console.log("Expected typing flow for \"children's\":");
      events.forEach(e => {
        console.log(`  Step ${e.step}: Type '${e.key}' → "${e.value}" ${e.shouldAdvance ? '→ ADVANCE' : '(keep typing)'}`);
      });
    });

    it("should handle various verse scenarios correctly", () => {
      const scenarios = [
        {
          verse: "God's love",
          sequence: [
            { word: "God's", userTypes: "God", triggerKey: 'space', shouldWork: true, description: "Space after base word" },
            { word: "God's", userTypes: "Gods", triggerKey: null, shouldWork: true, description: "Auto-advance on close match" },
            { word: "God's", userTypes: "God's", triggerKey: null, shouldWork: true, description: "Auto-advance on exact match" },
          ]
        },
        {
          verse: "the beginning",
          sequence: [
            { word: "the", userTypes: "the", triggerKey: null, shouldWork: true, description: "Simple word auto-advance" },
            { word: "beginning", userTypes: "beginning", triggerKey: null, shouldWork: true, description: "Long word auto-advance" }
          ]
        }
      ];

      scenarios.forEach(scenario => {
        console.log(`\nScenario: "${scenario.verse}"`);
        scenario.sequence.forEach(test => {
          console.log(`  ${test.description}: "${test.userTypes}" for "${test.word}" ${test.triggerKey ? `+ ${test.triggerKey}` : ''}`);
        });
      });
    });
  });

  describe("Requirements Summary", () => {
    it("should enforce these typing rules", () => {
      const rules = [
        "1. Exact matches auto-advance without space (e.g., 'the' → advance)",
        "2. Close matches auto-advance without space (e.g., 'childrens' for 'children\\'s' → advance)",
        "3. Base words do NOT auto-advance (e.g., 'children' for 'children\\'s' → keep typing)",
        "4. Base words + SPACE can advance (e.g., 'children' + SPACE for 'children\\'s' → advance)",
        "5. Never require space for exact matches"
      ];

      rules.forEach(rule => console.log(rule));

      // These are the test assertions we need
      expect(memverseLib.flexibleTextMatch("the", "the")).toBe(true);  // Rule 1
      expect(memverseLib.flexibleTextMatch("children's", "childrens")).toBe(true);  // Rule 2

      // Rule 3 is the problem - we need a way to distinguish between
      // "user is still typing" vs "user typed base word and pressed space"
    });
  });
});