/**
 * Review Order Conformance Tests
 *
 * These tests verify that the review order logic on /voice_review
 * conforms to the review order logic on /review.
 *
 * Both pages should:
 * 1. Start with the first due verse in a passage
 * 2. Advance to the next due verse after current when rating
 * 3. Check for skipped verses before current if no more after
 * 4. Advance to the next passage when all verses are reviewed
 * 5. Move incomplete passages to the end of the list
 * 6. Remove completed passages from the list
 * 7. Redirect to /progress when all passages are done
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

// Helper to create a mock verse with a specific due status
function createMockVerse(id, ref, text, dueInDays = -1) {
  const nextTest = new Date();
  nextTest.setDate(nextTest.getDate() + dueInDays);
  return {
    id: id,
    ref: ref,
    text: text,
    translation: 'NIV',
    versenum: id,
    next_test: nextTest.toISOString().split('T')[0]
  };
}

// Mock mvDue function (same logic as in memverse_lib.js)
function mvDue(mv) {
  const today = new Date();
  const reviewDateArray = mv.next_test.match(/(\d+)/g);
  const nextReviewDate = new Date(reviewDateArray[0], reviewDateArray[1] - 1, reviewDateArray[2]);
  return nextReviewDate < today;
}

/**
 * VoiceReviewState - extracted and simplified for testing
 * This mirrors the logic in voice_practice.html.erb
 */
function createVoiceReviewState() {
  return {
    passages: [],
    currentPassageId: null,
    currentPassageRef: null,
    passageVerses: [],
    currentVerseIndex: -1,
    currentVerse: null,
    completedPassages: [],
    movedToEndPassages: [],
    redirectedToProgress: false,

    // Load passages
    loadPassages: function(passages) {
      this.passages = passages.slice(); // Copy array
    },

    // Select a passage
    selectPassage: function(passageRef, passageId, verses) {
      this.currentPassageId = passageId;
      this.currentPassageRef = passageRef;
      this.passageVerses = Array.isArray(verses) ? verses : [verses];
      this.gotoFirstDueVerse();
    },

    // Find and display the first due verse in the passage
    gotoFirstDueVerse: function() {
      for (let i = 0; i < this.passageVerses.length; i++) {
        if (mvDue(this.passageVerses[i])) {
          this.currentVerseIndex = i;
          this.currentVerse = this.passageVerses[i];
          return i;
        }
      }
      // No due verses - should advance to next passage
      return this.autoAdvancePassage();
    },

    // Go to next due verse (same logic as reviewState.gotoNextVerseDue)
    gotoNextVerseDue: function() {
      // Look for next due verse AFTER current
      for (let i = this.currentVerseIndex + 1; i < this.passageVerses.length; i++) {
        if (mvDue(this.passageVerses[i])) {
          this.currentVerseIndex = i;
          this.currentVerse = this.passageVerses[i];
          return { action: 'next', index: i };
        }
      }

      // Check for skipped verses BEFORE current
      for (let i = 0; i < this.currentVerseIndex; i++) {
        if (mvDue(this.passageVerses[i])) {
          this.currentVerseIndex = i;
          this.currentVerse = this.passageVerses[i];
          return { action: 'skipped', index: i };
        }
      }

      // No more due verses in passage - advance to next passage
      return this.autoAdvancePassage();
    },

    // Mark current verse as reviewed (update local state)
    markCurrentVerseReviewed: function() {
      if (this.currentVerseIndex >= 0 && this.currentVerseIndex < this.passageVerses.length) {
        // Set next_test to tomorrow so mvDue returns false
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        this.passageVerses[this.currentVerseIndex].next_test = tomorrow.toISOString().split('T')[0];
      }
    },

    // Clear current passage and handle completion
    clearCurrentPassage: function() {
      const passageId = this.currentPassageId;

      if (passageId) {
        // Check if any verses still due
        let stillDue = false;
        for (let i = 0; i < this.passageVerses.length; i++) {
          if (mvDue(this.passageVerses[i])) {
            stillDue = true;
            break;
          }
        }

        if (stillDue) {
          // Move passage to end of list
          const passageIndex = this.passages.findIndex(p => p.id === passageId);
          if (passageIndex !== -1) {
            const passage = this.passages.splice(passageIndex, 1)[0];
            this.passages.push(passage);
            this.movedToEndPassages.push(passageId);
          }
        } else {
          // Remove from upcoming passages
          const passageIndex = this.passages.findIndex(p => p.id === passageId);
          if (passageIndex !== -1) {
            this.passages.splice(passageIndex, 1);
            this.completedPassages.push(passageId);
          }
        }
      }

      // Reset state
      this.currentPassageId = null;
      this.currentPassageRef = null;
      this.passageVerses = [];
      this.currentVerseIndex = -1;
      this.currentVerse = null;
    },

    // Advance to next passage
    autoAdvancePassage: function() {
      this.clearCurrentPassage();

      // Get next passage from list
      const nextPassage = this.passages[0];

      if (nextPassage) {
        return { action: 'nextPassage', passageId: nextPassage.id };
      } else {
        // No more passages - done for the day!
        this.redirectedToProgress = true;
        return { action: 'complete' };
      }
    }
  };
}

/**
 * ReviewState - DOM-based logic simulation for testing
 * This simulates the logic in memverse_passage_review.js
 */
function createReviewState() {
  return {
    passageList: [],
    currentPassageId: null,
    verses: [],
    currentVerseIndex: -1,
    completedPassages: [],
    movedToEndPassages: [],
    redirectedToProgress: false,

    loadPassages: function(passages) {
      this.passageList = passages.slice();
    },

    selectPassage: function(passageRef, passageId, verses) {
      this.currentPassageId = passageId;
      this.verses = Array.isArray(verses) ? verses : [verses];
      // Find first due verse
      this.currentVerseIndex = this.findFirstDueVerse();
    },

    findFirstDueVerse: function() {
      for (let i = 0; i < this.verses.length; i++) {
        if (mvDue(this.verses[i])) {
          return i;
        }
      }
      return -1;
    },

    // Simulates reviewState.gotoNextVerseDue logic
    gotoNextVerseDue: function() {
      // Look for next due verse after current (nextAll(".due-mv").first())
      for (let i = this.currentVerseIndex + 1; i < this.verses.length; i++) {
        if (mvDue(this.verses[i])) {
          this.currentVerseIndex = i;
          return { action: 'next', index: i };
        }
      }

      // Check for skipped verses (siblings(".due-mv"))
      for (let i = 0; i < this.currentVerseIndex; i++) {
        if (mvDue(this.verses[i])) {
          this.currentVerseIndex = i;
          return { action: 'skipped', index: i };
        }
      }

      // No more due - autoAdvancePassage
      return this.autoAdvancePassage();
    },

    markCurrentVerseReviewed: function() {
      if (this.currentVerseIndex >= 0) {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        this.verses[this.currentVerseIndex].next_test = tomorrow.toISOString().split('T')[0];
      }
    },

    clearCurrentPassage: function() {
      const passageId = this.currentPassageId;

      if (passageId) {
        // Check if any verses still due (passageNotReviewed = $(".due-mv").length)
        let stillDue = false;
        for (let i = 0; i < this.verses.length; i++) {
          if (mvDue(this.verses[i])) {
            stillDue = true;
            break;
          }
        }

        if (stillDue) {
          // Move to end of list
          const index = this.passageList.findIndex(p => p.id === passageId);
          if (index !== -1) {
            const passage = this.passageList.splice(index, 1)[0];
            this.passageList.push(passage);
            this.movedToEndPassages.push(passageId);
          }
        } else {
          // Remove from list
          const index = this.passageList.findIndex(p => p.id === passageId);
          if (index !== -1) {
            this.passageList.splice(index, 1);
            this.completedPassages.push(passageId);
          }
        }
      }

      this.currentPassageId = null;
      this.verses = [];
      this.currentVerseIndex = -1;
    },

    autoAdvancePassage: function() {
      this.clearCurrentPassage();

      const nextPassage = this.passageList[0];
      if (nextPassage) {
        return { action: 'nextPassage', passageId: nextPassage.id };
      } else {
        this.redirectedToProgress = true;
        return { action: 'complete' };
      }
    }
  };
}

describe('Review Order Conformance Tests', () => {

  describe('gotoFirstDueVerse behavior', () => {

    it('should start at the first due verse in a passage', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', 1),   // not due (tomorrow)
        createMockVerse(2, 'Gen 1:2', 'And the earth...', -1),     // due (yesterday)
        createMockVerse(3, 'Gen 1:3', 'And God said...', -1),      // due (yesterday)
      ];

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      // Both should start at index 1 (Gen 1:2, the first due verse)
      expect(voiceState.currentVerseIndex).toBe(1);
      expect(reviewState.currentVerseIndex).toBe(1);
      expect(voiceState.currentVerse.ref).toBe('Gen 1:2');
    });

    it('should start at the first verse if all are due', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
        createMockVerse(2, 'Gen 1:2', 'And the earth...', -1),
        createMockVerse(3, 'Gen 1:3', 'And God said...', -1),
      ];

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      expect(voiceState.currentVerseIndex).toBe(0);
      expect(reviewState.currentVerseIndex).toBe(0);
    });

  });

  describe('gotoNextVerseDue behavior', () => {

    it('should advance to the next due verse after current', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
        createMockVerse(2, 'Gen 1:2', 'And the earth...', -1),
        createMockVerse(3, 'Gen 1:3', 'And God said...', -1),
      ];

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      // Both start at index 0
      expect(voiceState.currentVerseIndex).toBe(0);
      expect(reviewState.currentVerseIndex).toBe(0);

      // Mark current verse as reviewed and go to next
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      // Both should advance to index 1
      expect(voiceResult.action).toBe('next');
      expect(reviewResult.action).toBe('next');
      expect(voiceState.currentVerseIndex).toBe(1);
      expect(reviewState.currentVerseIndex).toBe(1);
    });

    it('should skip non-due verses when advancing', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),  // due
        createMockVerse(2, 'Gen 1:2', 'And the earth...', 5),      // not due
        createMockVerse(3, 'Gen 1:3', 'And God said...', -1),      // due
      ];

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      // Both should skip index 1 and go to index 2
      expect(voiceResult.action).toBe('next');
      expect(reviewResult.action).toBe('next');
      expect(voiceState.currentVerseIndex).toBe(2);
      expect(reviewState.currentVerseIndex).toBe(2);
    });

    it('should find skipped verses when no more due verses after current', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
        createMockVerse(2, 'Gen 1:2', 'And the earth...', -1),
        createMockVerse(3, 'Gen 1:3', 'And God said...', -1),
      ];

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      // Manually move to last verse (simulating user skipping ahead)
      voiceState.currentVerseIndex = 2;
      voiceState.currentVerse = voiceState.passageVerses[2];
      reviewState.currentVerseIndex = 2;

      // Mark last verse as reviewed
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      // Should find skipped verse at index 0
      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('skipped');
      expect(reviewResult.action).toBe('skipped');
      expect(voiceState.currentVerseIndex).toBe(0);
      expect(reviewState.currentVerseIndex).toBe(0);
    });

    it('should advance to next passage when all verses are reviewed', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Genesis 1:1-3' },
        { id: 101, ref: 'Genesis 2:1-3' }
      ];

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('nextPassage');
      expect(reviewResult.action).toBe('nextPassage');
      expect(voiceResult.passageId).toBe(101);
      expect(reviewResult.passageId).toBe(101);
    });

  });

  describe('Passage completion behavior', () => {

    it('should remove completed passages from the list', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Genesis 1:1-3' },
        { id: 101, ref: 'Genesis 2:1-3' }
      ];

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      voiceState.gotoNextVerseDue();
      reviewState.gotoNextVerseDue();

      // Passage 100 should be completed and removed
      expect(voiceState.completedPassages).toContain(100);
      expect(reviewState.completedPassages).toContain(100);
      expect(voiceState.passages.find(p => p.id === 100)).toBeUndefined();
      expect(reviewState.passageList.find(p => p.id === 100)).toBeUndefined();
    });

    it('should move incomplete passages to end of list', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Genesis 1:1-3' },
        { id: 101, ref: 'Genesis 2:1-3' }
      ];

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
        createMockVerse(2, 'Gen 1:2', 'And the earth...', -1),
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1-3', 100, verses.map(v => ({...v})));

      // Review only first verse, leaving second as due
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      // Force advancement to next passage (simulating user clicking "Next Passage")
      voiceState.autoAdvancePassage();
      reviewState.autoAdvancePassage();

      // Passage 100 should be moved to end
      expect(voiceState.movedToEndPassages).toContain(100);
      expect(reviewState.movedToEndPassages).toContain(100);
      expect(voiceState.passages[voiceState.passages.length - 1].id).toBe(100);
      expect(reviewState.passageList[reviewState.passageList.length - 1].id).toBe(100);
    });

  });

  describe('Final completion behavior', () => {

    it('should redirect to progress when all passages are done', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Genesis 1:1' }
      ];

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1),
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('Genesis 1:1', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Genesis 1:1', 100, verses.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('complete');
      expect(reviewResult.action).toBe('complete');
      expect(voiceState.redirectedToProgress).toBe(true);
      expect(reviewState.redirectedToProgress).toBe(true);
    });

  });

  describe('Complex passage review scenarios', () => {

    it('should handle a multi-verse passage with some due, some not', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [{ id: 100, ref: 'Romans 12:1-5' }];

      const verses = [
        createMockVerse(1, 'Rom 12:1', 'Therefore I urge you...', -1),   // due
        createMockVerse(2, 'Rom 12:2', 'Do not conform...', 3),          // not due
        createMockVerse(3, 'Rom 12:3', 'For by the grace...', -1),       // due
        createMockVerse(4, 'Rom 12:4', 'For just as...', 5),             // not due
        createMockVerse(5, 'Rom 12:5', 'so in Christ...', -1),           // due
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('Romans 12:1-5', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Romans 12:1-5', 100, verses.map(v => ({...v})));

      // Should start at verse 1 (index 0)
      expect(voiceState.currentVerseIndex).toBe(0);
      expect(reviewState.currentVerseIndex).toBe(0);

      // Review verse 1
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();
      voiceState.gotoNextVerseDue();
      reviewState.gotoNextVerseDue();

      // Should skip verse 2 and go to verse 3 (index 2)
      expect(voiceState.currentVerseIndex).toBe(2);
      expect(reviewState.currentVerseIndex).toBe(2);

      // Review verse 3
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();
      voiceState.gotoNextVerseDue();
      reviewState.gotoNextVerseDue();

      // Should skip verse 4 and go to verse 5 (index 4)
      expect(voiceState.currentVerseIndex).toBe(4);
      expect(reviewState.currentVerseIndex).toBe(4);

      // Review verse 5 - should complete passage
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();
      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('complete');
      expect(reviewResult.action).toBe('complete');
    });

    it('should handle user skipping around in a passage', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [{ id: 100, ref: 'Psalm 23:1-3' }];

      const verses = [
        createMockVerse(1, 'Ps 23:1', 'The Lord is my shepherd...', -1),
        createMockVerse(2, 'Ps 23:2', 'He makes me lie down...', -1),
        createMockVerse(3, 'Ps 23:3', 'He restores my soul...', -1),
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('Psalm 23:1-3', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('Psalm 23:1-3', 100, verses.map(v => ({...v})));

      // User reviews verse 1
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      // User skips to verse 3 (index 2) without reviewing verse 2
      voiceState.currentVerseIndex = 2;
      voiceState.currentVerse = voiceState.passageVerses[2];
      reviewState.currentVerseIndex = 2;

      // Review verse 3
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      // Now go to next - should find skipped verse 2
      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('skipped');
      expect(reviewResult.action).toBe('skipped');
      expect(voiceState.currentVerseIndex).toBe(1);
      expect(reviewState.currentVerseIndex).toBe(1);
      expect(voiceState.currentVerse.ref).toBe('Ps 23:2');
    });

    it('should handle multiple passages in sequence', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Gen 1:1' },
        { id: 101, ref: 'John 3:16' },
        { id: 102, ref: 'Rom 8:28' }
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      // Review passage 1
      const verses1 = [createMockVerse(1, 'Gen 1:1', 'In the beginning...', -1)];
      voiceState.selectPassage('Gen 1:1', 100, verses1.map(v => ({...v})));
      reviewState.selectPassage('Gen 1:1', 100, verses1.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      let voiceResult = voiceState.gotoNextVerseDue();
      let reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('nextPassage');
      expect(reviewResult.action).toBe('nextPassage');
      expect(voiceResult.passageId).toBe(101);
      expect(reviewResult.passageId).toBe(101);

      // Review passage 2
      const verses2 = [createMockVerse(2, 'John 3:16', 'For God so loved...', -1)];
      voiceState.selectPassage('John 3:16', 101, verses2.map(v => ({...v})));
      reviewState.selectPassage('John 3:16', 101, verses2.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      voiceResult = voiceState.gotoNextVerseDue();
      reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('nextPassage');
      expect(reviewResult.action).toBe('nextPassage');
      expect(voiceResult.passageId).toBe(102);
      expect(reviewResult.passageId).toBe(102);

      // Review passage 3 (final)
      const verses3 = [createMockVerse(3, 'Rom 8:28', 'And we know...', -1)];
      voiceState.selectPassage('Rom 8:28', 102, verses3.map(v => ({...v})));
      reviewState.selectPassage('Rom 8:28', 102, verses3.map(v => ({...v})));

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      voiceResult = voiceState.gotoNextVerseDue();
      reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('complete');
      expect(reviewResult.action).toBe('complete');

      // All passages should be completed
      expect(voiceState.completedPassages).toEqual([100, 101, 102]);
      expect(reviewState.completedPassages).toEqual([100, 101, 102]);
    });

  });

  describe('Edge cases', () => {

    it('should handle single-verse passages', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [{ id: 100, ref: 'John 11:35' }];
      const verses = [createMockVerse(1, 'John 11:35', 'Jesus wept.', -1)];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      voiceState.selectPassage('John 11:35', 100, verses.map(v => ({...v})));
      reviewState.selectPassage('John 11:35', 100, verses.map(v => ({...v})));

      expect(voiceState.currentVerseIndex).toBe(0);
      expect(reviewState.currentVerseIndex).toBe(0);

      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();

      const voiceResult = voiceState.gotoNextVerseDue();
      const reviewResult = reviewState.gotoNextVerseDue();

      expect(voiceResult.action).toBe('complete');
      expect(reviewResult.action).toBe('complete');
    });

    it('should handle passage with no due verses', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Gen 1:1' },
        { id: 101, ref: 'Gen 1:2' }
      ];

      const verses = [
        createMockVerse(1, 'Gen 1:1', 'In the beginning...', 5), // not due
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      // When selecting a passage with no due verses, should auto-advance
      voiceState.selectPassage('Gen 1:1', 100, verses.map(v => ({...v})));

      // Voice state should have found no due verses and triggered auto-advance
      // (In the actual implementation, this would load the next passage)
      expect(voiceState.currentVerseIndex).toBe(-1);
    });

    it('should handle passage with verses wrapped in non-array', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [{ id: 100, ref: 'John 1:1' }];
      const singleVerse = createMockVerse(1, 'John 1:1', 'In the beginning was the Word...', -1);

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      // Pass single verse (not array) - should be wrapped
      voiceState.selectPassage('John 1:1', 100, singleVerse);
      reviewState.selectPassage('John 1:1', 100, singleVerse);

      expect(voiceState.passageVerses.length).toBe(1);
      expect(reviewState.verses.length).toBe(1);
      expect(voiceState.currentVerseIndex).toBe(0);
      expect(reviewState.currentVerseIndex).toBe(0);
    });

    it('should maintain order consistency across state resets', () => {
      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Passage A' },
        { id: 101, ref: 'Passage B' },
        { id: 102, ref: 'Passage C' }
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      // Complete first passage
      const versesA = [createMockVerse(1, 'A:1', 'Text A', -1)];
      voiceState.selectPassage('Passage A', 100, versesA.map(v => ({...v})));
      reviewState.selectPassage('Passage A', 100, versesA.map(v => ({...v})));
      voiceState.markCurrentVerseReviewed();
      reviewState.markCurrentVerseReviewed();
      voiceState.gotoNextVerseDue();
      reviewState.gotoNextVerseDue();

      // Verify next passage is B for both
      expect(voiceState.passages[0].id).toBe(101);
      expect(reviewState.passageList[0].id).toBe(101);

      // Skip B (leave it incomplete)
      const versesB = [
        createMockVerse(2, 'B:1', 'Text B1', -1),
        createMockVerse(3, 'B:2', 'Text B2', -1)
      ];
      voiceState.selectPassage('Passage B', 101, versesB.map(v => ({...v})));
      reviewState.selectPassage('Passage B', 101, versesB.map(v => ({...v})));
      voiceState.markCurrentVerseReviewed(); // Only review first verse
      reviewState.markCurrentVerseReviewed();
      voiceState.autoAdvancePassage(); // Force skip to next passage
      reviewState.autoAdvancePassage();

      // B should be moved to end
      expect(voiceState.passages[voiceState.passages.length - 1].id).toBe(101);
      expect(reviewState.passageList[reviewState.passageList.length - 1].id).toBe(101);

      // Next should be C
      expect(voiceState.passages[0].id).toBe(102);
      expect(reviewState.passageList[0].id).toBe(102);
    });

  });

  describe('Behavioral equivalence summary', () => {

    it('SUMMARY: voiceReviewState and reviewState should produce identical navigation sequences', () => {
      // This test simulates a complete review session and verifies
      // that both state machines produce identical results

      const voiceState = createVoiceReviewState();
      const reviewState = createReviewState();

      const passages = [
        { id: 100, ref: 'Psalm 1:1-3' },
        { id: 101, ref: 'Proverbs 3:5-6' }
      ];

      const psalm1Verses = [
        createMockVerse(1, 'Ps 1:1', 'Blessed is the man...', -1),
        createMockVerse(2, 'Ps 1:2', 'But his delight...', -1),
        createMockVerse(3, 'Ps 1:3', 'He is like a tree...', -1),
      ];

      const proverbs3Verses = [
        createMockVerse(4, 'Prov 3:5', 'Trust in the Lord...', -1),
        createMockVerse(5, 'Prov 3:6', 'In all your ways...', -1),
      ];

      voiceState.loadPassages(passages.map(p => ({...p})));
      reviewState.loadPassages(passages.map(p => ({...p})));

      const voiceActions = [];
      const reviewActions = [];

      // Review Psalm 1
      voiceState.selectPassage('Psalm 1:1-3', 100, psalm1Verses.map(v => ({...v})));
      reviewState.selectPassage('Psalm 1:1-3', 100, psalm1Verses.map(v => ({...v})));

      voiceActions.push({ verse: voiceState.currentVerseIndex });
      reviewActions.push({ verse: reviewState.currentVerseIndex });

      for (let i = 0; i < 3; i++) {
        voiceState.markCurrentVerseReviewed();
        reviewState.markCurrentVerseReviewed();
        const vr = voiceState.gotoNextVerseDue();
        const rr = reviewState.gotoNextVerseDue();
        voiceActions.push(vr);
        reviewActions.push(rr);
      }

      // Review Proverbs 3
      voiceState.selectPassage('Proverbs 3:5-6', 101, proverbs3Verses.map(v => ({...v})));
      reviewState.selectPassage('Proverbs 3:5-6', 101, proverbs3Verses.map(v => ({...v})));

      voiceActions.push({ verse: voiceState.currentVerseIndex });
      reviewActions.push({ verse: reviewState.currentVerseIndex });

      for (let i = 0; i < 2; i++) {
        voiceState.markCurrentVerseReviewed();
        reviewState.markCurrentVerseReviewed();
        const vr = voiceState.gotoNextVerseDue();
        const rr = reviewState.gotoNextVerseDue();
        voiceActions.push(vr);
        reviewActions.push(rr);
      }

      // Verify all actions match
      expect(voiceActions.length).toBe(reviewActions.length);
      for (let i = 0; i < voiceActions.length; i++) {
        expect(voiceActions[i]).toEqual(reviewActions[i]);
      }

      // Verify final state
      expect(voiceState.redirectedToProgress).toBe(true);
      expect(reviewState.redirectedToProgress).toBe(true);
      expect(voiceState.completedPassages).toEqual([100, 101]);
      expect(reviewState.completedPassages).toEqual([100, 101]);
    });

  });

});
