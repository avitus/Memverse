import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { memverseLib } from './helpers.js';

// Exercises the real flexibleTextMatch / scrub_text from
// app/assets/javascripts/memverse_lib.js (loaded via helpers.js).
// flexibleTextMatch(correctWord, userInput) decides whether a passage-review
// blank auto-advances, so every row below is a user-visible behaviour.
const { flexibleTextMatch, scrub_text, blankifyVerse } = memverseLib;

const EXODUS_20_17 =
  '"You shall not covet your neighbor\'s house; you shall not covet your neighbor\'s wife, ' +
  'or his male servant, or his female servant, or his ox, or his donkey, ' +
  'or anything that is your neighbor\'s."';

// [label, correctWord, userInput, expected]
const matchCases = [
  // --- exact match, including case ---
  ['exact: the / the', 'the', 'the', true],
  ['exact: God / God', 'God', 'God', true],
  ['exact: love / love', 'love', 'love', true],
  ['exact: beginning / beginning', 'beginning', 'beginning', true],
  ['exact: children / children', 'children', 'children', true],
  ['exact: The / The', 'The', 'The', true],
  ['exact: exact / exact', 'exact', 'exact', true],
  ['exact: word / word', 'word', 'word', true],
  ['exact: test / test', 'test', 'test', true],
  ['exact, case-insensitive: hello / HELLO', 'hello', 'HELLO', true],
  ['exact, case-insensitive: test / TEST', 'test', 'TEST', true],
  ["exact with apostrophe: neighbor's / neighbor's", "neighbor's", "neighbor's", true],
  ["exact with apostrophe: Lord's / Lord's", "Lord's", "Lord's", true],
  ["exact with apostrophe: children's / children's", "children's", "children's", true],
  ["exact with apostrophe: don't / don't", "don't", "don't", true],
  ["exact with apostrophe: can't / can't", "can't", "can't", true],
  ["exact with trailing apostrophe: Jesus' / Jesus'", "Jesus'", "Jesus'", true],
  ["exact with trailing apostrophe: James' / James'", "James'", "James'", true],

  // --- possessive typed without the apostrophe is accepted ---
  ["possessive without apostrophe: neighbor's -> neighbors", "neighbor's", 'neighbors', true],
  ["possessive without apostrophe: Lord's -> Lords", "Lord's", 'Lords', true],
  ["possessive without apostrophe: children's -> childrens", "children's", 'childrens', true],
  ["possessive without apostrophe: God's -> Gods", "God's", 'Gods', true],
  ["possessive without apostrophe, any case: Neighbor's -> NEIGHBORS", "Neighbor's", 'NEIGHBORS', true],

  // --- bare base word is rejected (prevents premature advance) ---
  ["base word rejected: neighbor's -> neighbor", "neighbor's", 'neighbor', false],
  ["base word rejected: Lord's -> Lord", "Lord's", 'Lord', false],
  ["base word rejected: children's -> children", "children's", 'children', false],
  ["base word rejected: man's -> man", "man's", 'man', false],
  ["base word rejected: don't -> don", "don't", 'don', false],
  ["base word rejected: can't -> can", "can't", 'can', false],
  ["base word rejected: won't -> won", "won't", 'won', false],
  ["base word rejected: I'm -> I", "I'm", 'I', false],
  ["base word rejected: you're -> you", "you're", 'you', false],
  ["base word rejected: we'll -> we", "we'll", 'we', false],
  ["base word rejected regardless of case: Neighbor's -> neighbor", "Neighbor's", 'neighbor', false],
  ["base word rejected regardless of case: neighbor's -> Neighbor", "neighbor's", 'Neighbor', false],

  // --- contraction typed without the apostrophe is accepted ---
  ["contraction without apostrophe: don't -> dont", "don't", 'dont', true],
  ["contraction without apostrophe: can't -> cant", "can't", 'cant', true],
  ["contraction without apostrophe: won't -> wont", "won't", 'wont', true],
  ["contraction without apostrophe: I'm -> Im", "I'm", 'Im', true],
  ["contraction without apostrophe: you're -> youre", "you're", 'youre', true],
  ["contraction without apostrophe: we'll -> well", "we'll", 'well', true],
  ["contraction without apostrophe, any case: DON'T -> dont", "DON'T", 'dont', true],
  ["contraction without apostrophe, any case: don't -> DONT", "don't", 'DONT', true],

  // --- trailing apostrophe is accepted via scrub_text ---
  ["trailing apostrophe scrubbed: Jesus' -> Jesus", "Jesus'", 'Jesus', true],
  ["trailing apostrophe scrubbed: disciples' -> disciples", "disciples'", 'disciples', true],
  ["trailing apostrophe scrubbed: Moses' -> Moses", "Moses'", 'Moses', true],
  ["trailing apostrophe scrubbed: James' -> James", "James'", 'James', true],

  // --- leading quotation mark is optional ---
  ['leading quote optional: "You -> You', '"You', 'You', true],
  ['leading quote optional: "The -> The', '"The', 'The', true],
  ['leading quote optional: "Lord -> Lord', '"Lord', 'Lord', true],
  ['leading quote optional: "children -> children', '"children', 'children', true],
  ["leading quote optional: 'Come -> Come", "'Come", 'Come', true],
  ["leading quote optional: 'The -> The", "'The", 'The', true],
  ['exact with leading quote: "You -> "You', '"You', '"You', true],
  ["exact with leading quote: 'Come -> 'Come", "'Come", "'Come", true],

  // --- trailing punctuation on the correct word ---
  ["trailing period: neighbor's. -> neighbor's", "neighbor's.", "neighbor's", true],
  ["trailing period: neighbor's. -> neighbors", "neighbor's.", 'neighbors', true],
  ["trailing period: neighbor's. -> neighbor's. (exact)", "neighbor's.", "neighbor's.", true],
  ["trailing period: neighbor's. -> neighbor (base rejected)", "neighbor's.", 'neighbor', false],
  ['trailing period+quote: neighbor\'s." -> neighbors', 'neighbor\'s."', 'neighbors', true],
  ['trailing period+quote: neighbor\'s." -> neighbor\'s', 'neighbor\'s."', "neighbor's", true],
  ['trailing period+quote: neighbor\'s." -> neighbor\'s." (exact)', 'neighbor\'s."', 'neighbor\'s."', true],
  ['trailing period+quote: neighbor\'s." -> neighbor (base rejected)', 'neighbor\'s."', 'neighbor', false],

  // --- false positives rejected ---
  ["different word rejected: neighbor's -> house", "neighbor's", 'house', false],
  ["different word rejected: don't -> do", "don't", 'do', false],
  ["different word rejected: can't -> car", "can't", 'car', false],
  ["different word rejected: Lord's -> King", "Lord's", 'King', false],
  ["different word rejected: I'm -> In", "I'm", 'In', false],
  ["different word rejected: you're -> your", "you're", 'your', false],
  ['different word rejected: "The -> A', '"The', 'A', false],
  ["different word rejected: children's -> adults", "children's", 'adults', false],
  ['different word rejected: children -> adult', 'children', 'adult', false],
  ['different word rejected: Lord -> King', 'Lord', 'King', false],
  ['different word rejected: test -> different', 'test', 'different', false],

  // --- empty strings ---
  ['empty vs empty matches', '', '', true],
  ['word vs empty does not match', 'word', '', false],
  ['empty vs word does not match', '', 'word', false],

  // --- progressive typing: no match until the word is complete ---
  ["progressive: neighbor's -> n", "neighbor's", 'n', false],
  ["progressive: neighbor's -> ne", "neighbor's", 'ne', false],
  ["progressive: neighbor's -> nei", "neighbor's", 'nei', false],
  ["progressive: neighbor's -> neig", "neighbor's", 'neig', false],
  ["progressive: neighbor's -> neigh", "neighbor's", 'neigh', false],
  ["progressive: neighbor's -> neighb", "neighbor's", 'neighb', false],
  ["progressive: neighbor's -> neighbo", "neighbor's", 'neighbo', false],
  ["progressive: neighbor's -> neighbor", "neighbor's", 'neighbor', false],
  ["progressive: neighbor's -> neighbor'", "neighbor's", "neighbor'", false],
  ["progressive: children's -> child", "children's", 'child', false],
  ["progressive: children's -> childre", "children's", 'childre', false],
  ["progressive: children's -> children'", "children's", "children'", false],
  ['progressive: the -> t', 'the', 't', false],
  ['progressive: the -> th', 'the', 'th', false],
];

// [input, expected]
const scrubCases = [
  ["neighbor's.", 'neighbors'],
  ['neighbor\'s."', 'neighbors'],
  ['neighbor', 'neighbor'],
  ['test123', 'test123'],
];

describe('flexibleTextMatch (memverse_lib.js)', () => {
  it.each(matchCases)('%s', (_label, correctWord, userInput, expected) => {
    expect(flexibleTextMatch(correctWord, userInput)).toBe(expected);
  });

  it.each(scrubCases)('scrub_text(%j) === %j', (input, expected) => {
    expect(scrub_text(input)).toBe(expected);
  });

  describe('blankifyVerse on Exodus 20:17', () => {
    beforeEach(() => {
      document.body.innerHTML = '<div class="passage-text"></div>';
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it.each([30, 40, 50])(
      "renders at least one input[name=\"neighbor's\"] at %i%% blanks",
      (percentage) => {
        const container = document.querySelector('.passage-text');
        container.innerHTML = blankifyVerse(EXODUS_20_17, percentage);

        const inputs = container.querySelectorAll('input[name="neighbor\'s"]');
        expect(inputs.length).toBeGreaterThan(0);

        // Every neighbor's blank follows the matching rules above.
        inputs.forEach((input) => {
          expect(flexibleTextMatch(input.name, 'neighbor')).toBe(false);
          expect(flexibleTextMatch(input.name, 'neighbors')).toBe(true);
          expect(flexibleTextMatch(input.name, "neighbor's")).toBe(true);
        });
      }
    );
  });
});
