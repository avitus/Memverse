import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("validPassageRef", () => {
  it("rejects single verse references", () => {
    expect(memverseLib.validPassageRef("Genesis 1:27")).toEqual( false );
  });

  it("accepts chapters", () => {
    expect(memverseLib.validPassageRef("Genesis 1")).toEqual( true );
  });

  it("accepts passages", () => {
    expect(memverseLib.validPassageRef("Genesis 1:1-5")).toEqual( true );
  });
});