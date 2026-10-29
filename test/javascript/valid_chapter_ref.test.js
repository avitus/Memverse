import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("validChapterRef", () => {
  it("accepts chapters", () => {
    expect(memverseLib.validChapterRef("Genesis 1")).toEqual( true );
  });

  it("accepts chapters with a trailing colon", () => {
    expect(memverseLib.validChapterRef("Genesis 12:")).toEqual( true );
  });

  it("rejects passages", () => {
    expect(memverseLib.validChapterRef("Genesis 1:1-5")).toEqual( false );
  });

  it("rejects single verse references", () => {
    expect(memverseLib.validChapterRef("Genesis 1:27")).toEqual( false );
  });
});