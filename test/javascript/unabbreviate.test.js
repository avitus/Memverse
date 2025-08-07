import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("Unabbreviate", () => {
  it("handles standard abbreviations", () => {
    expect(memverseLib.unabbreviate("Jn")).toEqual("John");
  });

  it("handles non-standard abbreviations", () => {
    expect(memverseLib.unabbreviate("Joh")).toEqual("John");
    expect(memverseLib.unabbreviate("Mat")).toEqual("Matthew");
  });

  it("accepts non-standard capitalization", () =>{
    expect(memverseLib.unabbreviate("JOHN")).toEqual("John");
    expect(memverseLib.unabbreviate("gEnE")).toEqual("Genesis");
  });

  it("fails when too general", () => {
    expect(memverseLib.unabbreviate("M")).toEqual("M");
  });

});
