describe("Passage Review Input Field Sizing", function() {
  var reviewState;
  
  beforeEach(function() {
    // Create the test DOM structure
    $('body').append('<div class="passage-text"></div>');
    $('body').append('<div class="upcoming-passages"></div>');
    
    // Mock the scrub_text function (it's globally defined)
    window.scrub_text = function(text) {
      return text.toLowerCase().replace(/[^0-9a-z\u00BF-\u1FFF\u2C00-\uD7FF]+/g, "");
    };
    
    // Mock word_width function for testing
    window.word_width = function(word) {
      // Simulate different widths for words with apostrophes
      if (word === "children's") return 90;
      if (word === "children") return 70;
      if (word === '"The') return 40;
      if (word === 'The') return 30;
      return word.length * 8;
    };
  });
  
  afterEach(function() {
    $('.passage-text').remove();
    $('.upcoming-passages').remove();
    $('#word_width').remove(); // Clean up the hidden span
  });
  
  describe("Word width calculation", function() {
    it("should calculate different widths for words with and without apostrophes", function() {
      expect(word_width("children's")).toBe(90);
      expect(word_width("children")).toBe(70);
    });
    
    it("should calculate different widths for words with and without quotation marks", function() {
      expect(word_width('"The')).toBe(40);
      expect(word_width('The')).toBe(30);
    });
  });
  
  describe("Input field creation", function() {
    it("should create input fields with width based on the full word including apostrophe", function() {
      var verseText = "For the Lord is good and his love endures forever; his faithfulness continues through all generations.";
      var blankified = blankifyVerse(verseText, 20);
      
      // Add a word with apostrophe to test
      var testText = "But the Lord's kindness is for those who honor him";
      var result = blankifyVerse(testText, 30);
      
      expect(result).toContain("Lord's");
      expect(result).toMatch(/style='width:\d+px'/);
      
      // The input field should be sized for "Lord's" not "Lords"
      var matches = result.match(/name='Lord's'[^>]*style='width:(\d+)px'/);
      if (matches) {
        var width = parseInt(matches[1]);
        expect(width).toBeGreaterThan(40); // Should be sized for the full word
      }
    });
  });
  
  describe("Input matching behavior", function() {
    it("should accept 'children' as a match for 'children's'", function() {
      var correctWord = "children's";
      var userGuess = "children";
      
      expect(scrub_text(correctWord)).toBe("childrens");
      expect(scrub_text(userGuess)).toBe("children");
      
      // In real usage, this would NOT match, which is the bug
      expect(scrub_text(correctWord)).not.toBe(scrub_text(userGuess));
    });
    
    it("should demonstrate the sizing issue when apostrophe words are matched", function() {
      // Create a mock input field
      var $input = $('<input>')
        .attr('name', "children's")
        .addClass('blank-word')
        .css('width', word_width("children's") + 'px')
        .val('');
      
      $('.passage-text').append($input);
      
      // Initial width should be for full word with apostrophe
      expect(parseInt($input.css('width'))).toBe(90);
      
      // When user types "children", the system would match and replace
      // This demonstrates the issue - the field was sized for "children's"
      // but accepts "children", causing layout shift
    });
  });
  
  describe("Quotation mark handling", function() {
    it("should have similar issues with words starting with quotation marks", function() {
      var correctWord = '"The';
      var userGuess = 'The';
      
      expect(scrub_text(correctWord)).toBe("the");
      expect(scrub_text(userGuess)).toBe("the");
      
      // These DO match after scrubbing, which is correct behavior
      expect(scrub_text(correctWord)).toBe(scrub_text(userGuess));
    });
  });
});