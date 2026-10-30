import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("validSubChapterPassage", () => {
  it("rejects single verse references", () => {
    expect(memverseLib.validSubChapterPassage("Genesis 1:27")).toEqual( false );
  });

  it("rejects whole-chapter references", () => {
    expect(memverseLib.validSubChapterPassage("Genesis 1")).toEqual( false );
  });

  it("accepts passages", () => {
    expect(memverseLib.validSubChapterPassage("Genesis 1:1-5")).toEqual( true );
  });
});