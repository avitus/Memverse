describe("parsePassageRef", function() {
  it("Parses a sub-chapter passage reference into chapter, book, start verse and end verse", function() {
    expect(parsePassageRef("Genesis 1:20-27")).toEqual( { bk: 'Genesis', ch: 1, vs_start: 20, vs_end: 27, bi: 1 } );
  });

  it("Parses a chapter reference into chapter, book", function() {
    expect(parsePassageRef("Genesis 1")).toEqual( { bk: 'Genesis', ch: 1, vs_start: null, vs_end: null, bi: 1 } );
  });
  
  it("Considers a chapter reference with a colon to still be a chapter and parses properly", function() {
    expect(parsePassageRef("Genesis 1:")).toEqual( { bk: 'Genesis', ch: 1, vs_start: null, vs_end: null, bi: 1 } );
  });

  it("Rejects single verses", function() {
    expect(parsePassageRef("Genesis 1:8")).toEqual( false );
  });

});