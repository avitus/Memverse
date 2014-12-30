describe("AccuracyTest", function() {
  it("handles arabic numbers", function() {
    accTestState.initialize(50);
    expect(accTestState.scoreRecitation("the number 100","the number 50")).toEqual(9);
  });

  it("ignores spaces and capitalization", function() {
    accTestState.initialize(50);
    expect(accTestState.scoreRecitation("   in the    beginning was the  word ","In the beginning was the Word.")).toEqual(10);
  });

});