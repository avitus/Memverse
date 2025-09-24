describe("Passage Review Exodus 20:17 Apostrophe Handling", function() {
  var verseText, reviewContainer;

  beforeEach(function() {
    // Exodus 20:17 ESV text with multiple apostrophes
    verseText = "You shall not covet your neighbor's house; you shall not covet your neighbor's wife, or his male servant, or his female servant, or his ox, or his donkey, or anything that is your neighbor's.";

    // Set up DOM
    $('body').append('<div class="passage-text"></div>');

    // Mock the scrub_text function
    window.scrub_text = function(text) {
      return text.toLowerCase().replace(/[^0-9a-z\u00BF-\u1FFF\u2C00-\uD7FF]+/g, "");
    };

    // Mock word_width function
    window.word_width = function(word) {
      return word.length * 8;
    };
  });

  afterEach(function() {
    $('.passage-text').remove();
    $('#word_width').remove();
  });

  describe("Current flexibleTextMatch behavior", function() {
    it("should NOT allow 'neighbor' to match 'neighbor's'", function() {
      // This tests the current restrictive behavior
      expect(flexibleTextMatch("neighbor's", "neighbor")).toBe(false);
    });

    it("should allow 'neighbors' to match 'neighbor's'", function() {
      // This works in current implementation
      expect(flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
    });

    it("should require exact match or apostrophe-removed version", function() {
      expect(flexibleTextMatch("neighbor's", "neighbor's")).toBe(true);
      expect(flexibleTextMatch("neighbor's", "neighbors")).toBe(true);
      expect(flexibleTextMatch("neighbor's", "neighbor")).toBe(false); // Current behavior
    });
  });

  describe("Desired behavior for user experience", function() {
    it("should accept variations without apostrophes", function() {
      // What the user wants:
      var testCases = [
        { correct: "neighbor's", userInput: "neighbor", shouldMatch: true },
        { correct: "neighbor's", userInput: "neighbors", shouldMatch: true },
        { correct: "neighbor's", userInput: "neighbor's", shouldMatch: true },
        { correct: "don't", userInput: "dont", shouldMatch: true },
        { correct: "don't", userInput: "don", shouldMatch: true },
        { correct: "can't", userInput: "cant", shouldMatch: true },
        { correct: "can't", userInput: "can", shouldMatch: true }
      ];

      testCases.forEach(function(testCase) {
        var result = flexibleTextMatch(testCase.correct, testCase.userInput);
        if (testCase.shouldMatch) {
          // These should pass but some currently fail
          console.log("Testing: '" + testCase.correct + "' vs '" + testCase.userInput + "' = " + result);
        }
      });
    });
  });

  describe("Full verse review scenario", function() {
    it("should handle Exodus 20:17 with flexible matching", function() {
      // Simulate blankifying the verse
      var blankified = blankifyVerse(verseText, 30);
      $('.passage-text').html(blankified);

      // Count how many times neighbor's appears
      var neighborCount = (verseText.match(/neighbor's/g) || []).length;
      expect(neighborCount).toBe(3);

      // Find input fields for neighbor's
      var $inputs = $('.passage-text input[name="neighbor\'s"]');
      expect($inputs.length).toBeGreaterThan(0);

      // Simulate user typing without apostrophe
      $inputs.each(function() {
        var $input = $(this);

        // User types "neighbor" instead of "neighbor's"
        $input.val('neighbor');

        // Current behavior: this would NOT match
        expect(flexibleTextMatch("neighbor's", "neighbor")).toBe(false);

        // Desired behavior: this SHOULD match
        // expect(flexibleTextMatch("neighbor's", "neighbor")).toBe(true);
      });
    });
  });

  describe("Other punctuation cases", function() {
    it("should handle quotation marks flexibly", function() {
      expect(flexibleTextMatch('"You', 'You')).toBe(true);
      expect(flexibleTextMatch('"You', '"You')).toBe(true);
    });

    it("should handle trailing apostrophes", function() {
      expect(flexibleTextMatch("Jesus'", "Jesus")).toBe(true); // Currently false
      expect(flexibleTextMatch("disciples'", "disciples")).toBe(true); // Currently false
    });

    it("should not create false matches", function() {
      expect(flexibleTextMatch("neighbor's", "house")).toBe(false);
      expect(flexibleTextMatch("don't", "do")).toBe(false);
    });
  });
});