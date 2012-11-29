describe("blankifyVerse", function() {
  
  it("replaces 10% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 10))
    .toEqual("In the <input name='beginning' class='blank-word' style='width:5.58em;'> God created the heavens and the earth");
  });  

  it("replaces 40% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 40))
    .toEqual("In the <input name='beginning' class='blank-word' style='width:5.58em;'> God <input name='created' class='blank-word' style='width:4.34em;'> the <input name='heavens' class='blank-word' style='width:4.34em;'> and the <input name='earth' class='blank-word' style='width:3.1em;'>");
  }); 

  it("replaces plain apostrophes with fancy ones", function() {
    expect(blankifyVerse("for his name's sake", 40))
    .toEqual("for his <input name='name’s' class='blank-word' style='width:3.72em;'> <input name='sake' class='blank-word' style='width:2.48em;'>");
  }); 

});