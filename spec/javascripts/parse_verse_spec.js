describe("ParseVerse", function() {
  it("parses a verse reference into chapter, book and verse", function() {
    expect(parseVerseRef("Genesis 1:27")).toEqual( { bk: 'Genesis', ch: 1, vs: 27 } );
  });

  it("parses a verse reference into chapter, book and verse and handles leading numbers", function() {
    expect(parseVerseRef("2 Corinthians 1:27")).toEqual( { bk: '2 Corinthians', ch: 1, vs: 27 } );
  });
  
  it("parses a verse reference into chapter, book and verse and handles book names with spaces", function() {
    expect(parseVerseRef("Song of Songs 2:4")).toEqual( { bk: 'Song of Songs', ch: 2, vs: 4 } );
  });
  
  it("parses a verse reference into chapter, book and verse, but rejects references without a verse", function() {
    expect(parseVerseRef("Genesis 1")).toEqual( false );
  });

  it("parses a verse reference into chapter, book and verse, but rejects non-canonical books", function() {
    expect(parseVerseRef("Ecclesiasticus 1:2")).toEqual( false );
  });


});