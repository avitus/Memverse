describe("ParseVerse", function() {
  it("Parses a verse reference into chapter, book and verse", function() {
    expect(parseVerseRef("Genesis 1:27")).toEqual( { bk: 'Genesis', ch: 1, vs: 27, bi: 1 } );
  });

  it("Handles leading numbers", function() {
    expect(parseVerseRef("2 Corinthians 1:27")).toEqual( { bk: '2 Corinthians', ch: 1, vs: 27, bi: 47 } );
  });

  it("Handles book names with spaces", function() {
    expect(parseVerseRef("Song of Songs 2:4")).toEqual( { bk: 'Song of Songs', ch: 2, vs: 4, bi: 22 } );
  });

  it("Handles lowercase book names", function() {
    expect(parseVerseRef("romans 8:1")).toEqual( { bk: 'Romans', ch: 8, vs: 1, bi: 45 } );
  });

  it("Handles multiword lowercase book names", function() {
    expect(parseVerseRef("song of songs 2:1")).toEqual( { bk: 'Song of Songs', ch: 2, vs: 1, bi: 22 } );
  });

  it("Converts 'Psalm' to 'Psalms'", function() {
    expect(parseVerseRef("Psalm 1:1")).toEqual(  { bk: 'Psalms', ch: 1, vs: 1, bi: 19 } );
    expect(parseVerseRef("Psalms 1:2")).toEqual( { bk: 'Psalms', ch: 1, vs: 2, bi: 19 } );
    expect(parseVerseRef("psalm 1:3")).toEqual(  { bk: 'Psalms', ch: 1, vs: 3, bi: 19 } );
    expect(parseVerseRef("psalms 1:4")).toEqual( { bk: 'Psalms', ch: 1, vs: 4, bi: 19 } );
  });

  it("Handles Roman numerals properly", function() {
    expect(parseVerseRef("III John 1:2")).toEqual({ bk: '3 John', ch: 1, vs: 2, bi: 64 } );
    expect(parseVerseRef("II John 1:4")).toEqual( { bk: '2 John', ch: 1, vs: 4, bi: 63 } );
    expect(parseVerseRef("I John 1:9")).toEqual(  { bk: '1 John', ch: 1, vs: 9, bi: 62 } );
    expect(parseVerseRef("Malachi 4:6")).toEqual( { bk: 'Malachi', ch: 4, vs: 6, bi: 39 } ); // don't want "i" in Malachi taken for a Roman numeral
  });

  it("Handles lowercase book names with leading number", function() {
    expect(parseVerseRef("1 corinthians 8:1")).toEqual( { bk: '1 Corinthians', ch: 8, vs: 1, bi: 46 } );
  });

  it("Handles abbreviations such as rom 8:1", function() {
    expect(parseVerseRef("rom 8:1")).toEqual( { bk: 'Romans', ch: 8, vs: 1, bi: 45 } );
  });

  it("Handles space between colon and verse", function() {
    expect(parseVerseRef("Romans 2: 1")).toEqual( { bk: 'Romans', ch: 2, vs: 1, bi: 45 } );
  });

  it("Rejects references without a verse", function() {
    expect(parseVerseRef("Genesis 1")).toEqual( false );
  });

  it("Rejects non-canonical books", function() {
    expect(parseVerseRef("Ecclesiasticus 1:2")).toEqual( false );
  });

});
