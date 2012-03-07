describe("validVerseRef", function() {
  it("accepts single verse references", function() {
    expect(validVerseRef("Genesis 1:27")).toEqual( true );
  });
  
  it("rejects chapters", function() {
    expect(validVerseRef("Genesis 1")).toEqual( false );
  });
  
  it("rejects passages", function() {
    expect(validVerseRef("Genesis 1:1-5")).toEqual( false );
  });
});