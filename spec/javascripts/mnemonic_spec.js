describe("mnemonic", function() {
  it("works for English", function() {
    expect(mnemonic("'There is therefore now no condemnation'!")).toEqual( "'T i t n n c'!" );
  });

  it("works for other languages", function() {
    expect(mnemonic("áâ αβξδεφγη 이두 鄕札")).toEqual( "á α 이 鄕" );
  });
});
