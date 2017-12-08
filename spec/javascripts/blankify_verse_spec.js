//= require support/jquery-2.0.2.min.js
//= require support/jquery-ui.min.js
//= require application


// Note: These test behave differently depending on the exact browser environment. The width of each blank will be
//       slightly different

describe("blankifyVerse", function() {

  it("replaces 10% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 10))
    .toEqual("<span>In </span> <span>the </span> <input name='beginning' class='blank-word' style='width:95px' autocomplete='off'> <span>God </span> <span>created </span> <span>the </span> <span>heavens </span> <span>and </span> <span>the </span> <span>earth </span>");
  });

  it("replaces 40% of words in a verse with blanks", function() {
    expect(blankifyVerse("In the beginning God created the heavens and the earth", 40))
    .toEqual("<span>In </span> <span>the </span> <input name='beginning' class='blank-word' style='width:95px' autocomplete='off'> <span>God </span> <input name='created' class='blank-word' style='width:73px' autocomplete='off'> <span>the </span> <input name='heavens' class='blank-word' style='width:78px' autocomplete='off'> <span>and </span> <span>the </span> <input name='earth' class='blank-word' style='width:51px' autocomplete='off'>");
  });

  it("replaces plain apostrophes with fancy ones", function() {
    expect(blankifyVerse("for his name's sake", 40))
    .toEqual("<span>for </span> <span>his </span> <input name='name’s' class='blank-word' style='width:67px' autocomplete='off'> <input name='sake' class='blank-word' style='width:44px' autocomplete='off'>");
  });

});
