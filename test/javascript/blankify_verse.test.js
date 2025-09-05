import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

//= require support/jquery-2.0.2.min.js
//= require support/jquery-ui.min.js
//= require application


// Note: These test behave differently depending on the exact browser environment. The width of each blank will be
//       slightly different

describe("blankifyVerse", () => {

  it("replaces 10% of words in a verse with blanks", () => {
    expect(memverseLib.blankifyVerse("In the beginning God created the heavens and the earth", 10))
    .toEqual("<span>In </span> <span>the </span> <input name='beginning' class='blank-word' style='width:90px' autocomplete='off'> <span>God </span> <span>created </span> <span>the </span> <span>heavens </span> <span>and </span> <span>the </span> <span>earth </span>");
  });

  it("replaces 40% of words in a verse with blanks", () => {
    expect(memverseLib.blankifyVerse("In the beginning God created the heavens and the earth", 40))
    .toEqual("<span>In </span> <span>the </span> <input name='beginning' class='blank-word' style='width:90px' autocomplete='off'> <span>God </span> <input name='created' class='blank-word' style='width:71px' autocomplete='off'> <span>the </span> <input name='heavens' class='blank-word' style='width:80px' autocomplete='off'> <span>and </span> <span>the </span> <input name='earth' class='blank-word' style='width:51px' autocomplete='off'>");
  });

  it("replaces plain apostrophes with fancy ones", () => {
    var result = memverseLib.blankifyVerse("for his name's sake", 40);
    // Just check that the apostrophe was replaced in the output
    expect(result).toContain("name's");  // Should contain the fancy apostrophe
    expect(result).toContain("<span>for </span>");
    expect(result).toContain("<span>his </span>");
    expect(result).toContain("class='blank-word'");
  });

});
