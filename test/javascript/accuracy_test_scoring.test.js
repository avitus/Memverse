import { describe, it, expect } from 'vitest';
import { memverseLib, memverse, memverseAccuracy, liveQuiz } from './helpers.js';

const accTestState = memverseAccuracy.accTestState;
// Make calculate_levenshtein_distance available globally as expected by accTestState
global.calculate_levenshtein_distance = liveQuiz.calculate_levenshtein_distance;

describe("AccuracyTest", () => {
  it("handles arabic numbers", () => {
    accTestState.initialize(50);
    expect(accTestState.scoreRecitation("the number 100","the number 50")).toEqual(9);
  });

  it("ignores spaces and capitalization", () => {
    accTestState.initialize(50);
    expect(accTestState.scoreRecitation("   in the    beginning was the  word ","In the beginning was the Word.")).toEqual(10);
  });

});