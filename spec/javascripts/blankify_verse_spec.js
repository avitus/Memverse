describe("blankifyVerse", function() {

  it("replaces 10% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 10))
    .toEqual("<span>In </span> <span>the </span> <input name='beginning' class='blank-word' style='width:94px'> <span>God </span> <span>created </span> <span>the </span> <span>heavens </span> <span>and </span> <span>the </span> <span>earth </span>");
  });

  it("replaces 40% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 40))
    .toEqual("<span>In </span> <span>the </span> <input name='beginning' class='blank-word' style='width:94px'> <span>God </span> <input name='created' class='blank-word' style='width:71px'> <span>the </span> <input name='heavens' class='blank-word' style='width:76px'> <span>and </span> <span>the </span> <input name='earth' class='blank-word' style='width:50px'>");
  });

  it("replaces plain apostrophes with fancy ones", function() {
    expect(blankifyVerse("for his name's sake", 40))
    .toEqual("<span>for </span> <span>his </span> <input name='name’s' class='blank-word' style='width:65px'> <input name='sake' class='blank-word' style='width:42px'>");
  });

});