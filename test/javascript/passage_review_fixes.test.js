import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { memverseLib } from './helpers.js';

// Input-field sizing and attribute escaping for passage-review blanks
// (blankifyVerse / calculateInputWidth in app/assets/javascripts/memverse_lib.js).
// Word matching lives in flexible_text_match.test.js.
//
// Note: calculateInputWidth closes over the word_width that helpers.js injects
// (the setup.js mock), so widths are asserted relative to that function rather
// than as hard-coded pixel values.
const { blankifyVerse, calculateInputWidth, word_width } = memverseLib;

describe('Passage review input field sizing and escaping', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div class="passage-text"></div>';
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('calculateInputWidth', () => {
    it.each(["children's", '"The', "Lord's", 'the'])(
      'returns word_width(%j) plus an 8px buffer',
      (word) => {
        expect(calculateInputWidth(word)).toBe(word_width(word) + 8);
      }
    );
  });

  describe('blankifyVerse attribute escaping', () => {
    it('writes an apostrophe word into a double-quoted name attribute with the buffered width', () => {
      const result = blankifyVerse("But the Lord's kindness is for those who honor him", 30);

      expect(result).toContain('name="Lord\'s"');
      expect(result).toContain('style="width:' + calculateInputWidth("Lord's") + 'px"');
    });

    it("escapes God's and children's using double-quoted name attributes", () => {
      const result = blankifyVerse("For God's glory and children's sake we pray", 50);

      expect(result).toContain('name="God\'s"');
      expect(result).toContain('name="children\'s"');
      expect(result).toMatch(/name="[^"]*"/);
    });

    it('escapes a leading double quote in the name attribute as &quot;', () => {
      const result = blankifyVerse('"The Lord is my shepherd," he said proudly', 40);

      expect(result).toContain('name="&quot;The');
    });

    it('produces input.blank-word elements whose DOM name keeps the apostrophe', () => {
      const container = document.querySelector('.passage-text');
      container.innerHTML = blankifyVerse("For the children's sake and the Lord's glory", 50);

      const names = Array.from(container.querySelectorAll('input.blank-word')).map((i) => i.name);
      expect(names).toContain("children's");
      expect(names).toContain("Lord's");
    });
  });
});
