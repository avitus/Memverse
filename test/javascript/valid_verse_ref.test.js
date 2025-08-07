import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("validVerseRef", () => {
  it("accepts single verse references", () => {
    expect(memverseLib.validVerseRef("Genesis 1:27")).toEqual( true );
  });

  it("rejects chapters", () => {
    expect(memverseLib.validVerseRef("Genesis 1")).toEqual( false );
  });

  it("rejects passages", () => {
    expect(memverseLib.validVerseRef("Genesis 1:1-5")).toEqual( false );
  });
});