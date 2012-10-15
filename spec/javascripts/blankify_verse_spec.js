describe("blankifyVerse", function() {
  
  it("replaces 10% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 10))
    .toEqual("In the <span class='blank-word'>_____</span> God created the heavens and the earth");
  });  

  it("replaces 40% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 40))
    .toEqual("In the <span class='blank-word'>_____</span> God <span class='blank-word'>_____</span> the <span class='blank-word'>_____</span> and the <span class='blank-word'>_____</span>");
  }); 

});