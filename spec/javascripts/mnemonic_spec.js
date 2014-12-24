describe("mnemonic", function() {
  it("works for English", function() {
    expect(mnemonic("'There is therefore now no condemnation'!")).toEqual( "'T i t n n c'!" );
  });

  it("works for Korean", function() {
    expect(mnemonic("말씀하시되 나를 따라오라 내가 너희를 사람을 낚는 어부가 되게 하리라 하시니")).toEqual( "ᄆᄊᄒᄉᄃ ᄂᄅ ᄄᄅᄋᄅ ᄂᄀ ᄂᄒᄅ ᄉᄅᄋ ᄂᄂ ᄋᄇᄀ ᄃᄀ ᄒᄅᄅ ᄒᄉᄂ" );
  });

  it("works for other languages", function() {
    expect(mnemonic("áâ αβξδεφγη 鄕札")).toEqual( "á α 鄕" );
  });
  
});
