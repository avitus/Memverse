import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("parseVerseRef", () => {
  it("parses a verse reference into chapter, book and verse", () => {
    expect(memverseLib.parseVerseRef("Genesis 1:27")).toEqual( { bk: 'Genesis', ch: 1, vs: 27, bi: 1 } );
  });

  it("allows leading numbers", () => {
    expect(memverseLib.parseVerseRef("2 Corinthians 1:27")).toEqual( { bk: '2 Corinthians', ch: 1, vs: 27, bi: 47 } );
  });

  it("allows book names with spaces", () => {
    expect(memverseLib.parseVerseRef("Song of Songs 2:4")).toEqual( { bk: 'Song of Songs', ch: 2, vs: 4, bi: 22 } );
  });

  it("accepts lowercase book names", () => {
    expect(memverseLib.parseVerseRef("romans 8:1")).toEqual( { bk: 'Romans', ch: 8, vs: 1, bi: 45 } );
  });

  it("accepts multiword lowercase book names", () => {
    expect(memverseLib.parseVerseRef("song of songs 2:1")).toEqual( { bk: 'Song of Songs', ch: 2, vs: 1, bi: 22 } );
  });

  it("converts 'Psalm' to 'Psalms'", () => {
    expect(memverseLib.parseVerseRef("Psalm 1:1")).toEqual(  { bk: 'Psalms', ch: 1, vs: 1, bi: 19 } );
    expect(memverseLib.parseVerseRef("Psalms 1:2")).toEqual( { bk: 'Psalms', ch: 1, vs: 2, bi: 19 } );
    expect(memverseLib.parseVerseRef("psalm 1:3")).toEqual(  { bk: 'Psalms', ch: 1, vs: 3, bi: 19 } );
    expect(memverseLib.parseVerseRef("psalms 1:4")).toEqual( { bk: 'Psalms', ch: 1, vs: 4, bi: 19 } );
  });

  it("accepts Roman numerals", () => {
    expect(memverseLib.parseVerseRef("III John 1:2")).toEqual({ bk: '3 John', ch: 1, vs: 2, bi: 64 } );
    expect(memverseLib.parseVerseRef("II John 1:4")).toEqual( { bk: '2 John', ch: 1, vs: 4, bi: 63 } );
    expect(memverseLib.parseVerseRef("I John 1:9")).toEqual(  { bk: '1 John', ch: 1, vs: 9, bi: 62 } );
    expect(memverseLib.parseVerseRef("Malachi 4:6")).toEqual( { bk: 'Malachi', ch: 4, vs: 6, bi: 39 } ); // don't want "i" in Malachi taken for a Roman numeral
  });

  it("accepts incorrectly capitalized Roman numerals", () =>{
    expect(memverseLib.parseVerseRef("Ii John 1:2")).toEqual({ bk: '2 John', ch: 1, vs: 2, bi: 63 } );
  })

  it("Handles lowercase book names with leading number", () => {
    expect(memverseLib.parseVerseRef("1 corinthians 8:1")).toEqual( { bk: '1 Corinthians', ch: 8, vs: 1, bi: 46 } );
  });

  it("Handles abbreviations such as rom 8:1", () => {
    expect(memverseLib.parseVerseRef("rom 8:1")).toEqual( { bk: 'Romans', ch: 8, vs: 1, bi: 45 } );
  });

  it("Handles space between colon and verse", () => {
    expect(memverseLib.parseVerseRef("Romans 2: 1")).toEqual( { bk: 'Romans', ch: 2, vs: 1, bi: 45 } );
  });

  it("Rejects references without a verse", () => {
    expect(memverseLib.parseVerseRef("Genesis 1")).toEqual( false );
  });

  it("Rejects non-canonical books", () => {
    expect(memverseLib.parseVerseRef("Ecclesiasticus 1:2")).toEqual( false );
  });

});
