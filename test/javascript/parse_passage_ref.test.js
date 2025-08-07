import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("parsePassageRef", () => {
  it("Parses a sub-chapter passage reference into chapter, book, start verse and end verse", () => {
    expect(memverseLib.parsePassageRef("Genesis 1:20-27")).toEqual( { bk: 'Genesis', ch: 1, vs_start: 20, vs_end: 27, bi: 1 } );
  });

  it("Parses a chapter reference into chapter, book", () => {
    expect(memverseLib.parsePassageRef("Genesis 1")).toEqual( { bk: 'Genesis', ch: 1, vs_start: null, vs_end: null, bi: 1 } );
  });

  it("Considers a chapter reference with a colon to still be a chapter and parses properly", () => {
    expect(memverseLib.parsePassageRef("Genesis 1:")).toEqual( { bk: 'Genesis', ch: 1, vs_start: null, vs_end: null, bi: 1 } );
  });

  it("Accepts a passage reference with a space after the colon and before the verse numbers", () => {
    expect(memverseLib.parsePassageRef("Genesis 1: 5-8")).toEqual( { bk: 'Genesis', ch: 1, vs_start: 5, vs_end: 8, bi: 1 } );
  });

  it("Rejects single verses", () => {
    expect(memverseLib.parsePassageRef("Genesis 1:8")).toEqual( false );
  });

});