describe("validPassageRef", function() {
  it("rejects single verse references", function() {
    expect(validPassageRef("Genesis 1:27")).toEqual( false );
  });
  
  it("accepts chapters", function() {
    expect(validPassageRef("Genesis 1")).toEqual( true );
  });
  
  it("accepts passages", function() {
    expect(validPassageRef("Genesis 1:1-5")).toEqual( true );
  });
});