describe("Unabbreviate", function() {
  it("handles standard abbreviations", function() {
    expect(unabbreviate("Jn")).toEqual("John");
  });
  it("handles non-standard abbreviations", function() {
    expect(unabbreviate("Joh")).toEqual("John");
    expect(unabbreviate("Mat")).toEqual("Matthew");
  });
  it("fails when too general", function() {
    expect(unabbreviate("M")).toEqual("M");
  });
});
