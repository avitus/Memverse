describe("validVerseRef", function() {
  it("accepts chapters", function() {
    expect(validChapterRef("Genesis 1")).toEqual( true );
  });

  it("accepts chapters", function() {
    expect(validChapterRef("Genesis 12:")).toEqual( true );
  });

  it("rejects passages", function() {
    expect(validChapterRef("Genesis 1:1-5")).toEqual( false );
  });

  it("rejects single verse references", function() {
    expect(validChapterRef("Genesis 1:27")).toEqual( false );
  });
});