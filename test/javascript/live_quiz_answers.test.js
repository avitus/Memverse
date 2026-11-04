import { describe, it, expect } from 'vitest';
import { memverseLib } from './helpers.js';

const liveQuizAnswerProblem = memverseLib.liveQuizAnswerProblem;
const liveQuizFeedback = memverseLib.liveQuizFeedback;

describe('liveQuizAnswerProblem', () => {
  it('asks for a choice when no multiple choice option is selected', () => {
    expect(liveQuizAnswerProblem('mcq', undefined)).toMatch(/choose an answer/i);
  });

  it('accepts a selected multiple choice option', () => {
    expect(liveQuizAnswerProblem('mcq', 'b')).toBeNull();
  });

  it('asks for words when a recitation is empty', () => {
    expect(liveQuizAnswerProblem('recitation', '   ')).toMatch(/recite the verse/i);
  });

  it('accepts a recitation with words', () => {
    expect(liveQuizAnswerProblem('recitation', 'Jesus wept')).toBeNull();
  });

  it('asks for Book Chapter:Verse when a reference is malformed', () => {
    expect(liveQuizAnswerProblem('reference', 'John')).toMatch(/Book Chapter:Verse/);
    expect(liveQuizAnswerProblem('reference', 'John 3')).toMatch(/Book Chapter:Verse/);
    expect(liveQuizAnswerProblem('reference', '')).toMatch(/Book Chapter:Verse/);
  });

  it('accepts a reference with book, chapter and verse', () => {
    expect(liveQuizAnswerProblem('reference', 'John 3:16')).toBeNull();
    expect(liveQuizAnswerProblem('reference', '1 John 1:9-10')).toBeNull();
  });
});

describe('liveQuizFeedback', () => {
  it('congratulates a perfect score', () => {
    expect(liveQuizFeedback({ status: 'graded', score: 10 })).toMatch(/10 points/);
  });

  it('reports partial credit', () => {
    expect(liveQuizFeedback({ status: 'graded', score: 7 })).toMatch(/7 points/);
  });

  it('reports a wrong answer without giving the answer away', () => {
    expect(liveQuizFeedback({ status: 'graded', score: 0 })).toMatch(/not correct/i);
  });

  it('explains a late answer', () => {
    expect(liveQuizFeedback({ status: 'closed', score: null })).toMatch(/closed/i);
  });

  it('explains a repeated answer', () => {
    expect(liveQuizFeedback({ status: 'duplicate', score: null })).toMatch(/already answered/i);
  });
});
