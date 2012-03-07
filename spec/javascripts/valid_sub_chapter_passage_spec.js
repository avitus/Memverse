describe("validSubChapterPassage", function() {
  it("rejects single verse references", function() {
    expect(validSubChapterPassage("Genesis 1:27")).toEqual( false );
  });
  
  it("accepts chapters", function() {
    expect(validSubChapterPassage("Genesis 1")).toEqual( false );
  });
  
  it("accepts passages", function() {
    expect(validSubChapterPassage("Genesis 1:1-5")).toEqual( true );
  });
});