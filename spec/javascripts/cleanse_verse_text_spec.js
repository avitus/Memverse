describe("CleanseVerseText", function() {
  it("removes trailing and leading whitespace", function() {
    expect(cleanseVerseText("    in the beginning   ")).toEqual("in the beginning");
  });

  it("collapses unnecessary whitespace", function() {
    expect(cleanseVerseText("in    the   beginning")).toEqual("in the beginning");
  });

  it("removes newlines", function() {
    expect(cleanseVerseText("in the\nbeginning")).toEqual("in the beginning");
  });

  it("ensures spaces around long dashes", function() {
    expect(cleanseVerseText("we are heirs—heirs of God and co-heirs with Christ")).toEqual("we are heirs — heirs of God and co-heirs with Christ");
  });

  it("replaces double dashes with long dash ", function() {
    expect(cleanseVerseText("we are heirs--heirs of God and co-heirs with Christ")).toEqual("we are heirs — heirs of God and co-heirs with Christ");
  });

  it("removes footnotes", function() {
    expect(cleanseVerseText("that[i] the creation[j] itself")).toEqual("that the creation itself");
  });

});