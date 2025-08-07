import { describe, it, expect } from 'vitest';
import { memverseLib, memverse } from './helpers.js';

describe("CleanseVerseText", () => {
  it("removes trailing and leading whitespace", () => {
    expect(memverseLib.cleanseVerseText("    in the beginning   ")).toEqual("in the beginning");
  });

  it("collapses unnecessary whitespace", () => {
    expect(memverseLib.cleanseVerseText("in    the   beginning")).toEqual("in the beginning");
  });

  it("removes newlines", () => {
    expect(memverseLib.cleanseVerseText("in the\nbeginning")).toEqual("in the beginning");
  });

  it("ensures spaces around long dashes", () => {
    expect(memverseLib.cleanseVerseText("we are heirs—heirs of God and co-heirs with Christ")).toEqual("we are heirs — heirs of God and co-heirs with Christ");
  });

  it("replaces double dashes with long dash ", () => {
    expect(memverseLib.cleanseVerseText("we are heirs--heirs of God and co-heirs with Christ")).toEqual("we are heirs — heirs of God and co-heirs with Christ");
  });

  it("removes footnotes", () => {
    expect(memverseLib.cleanseVerseText("that[i] the creation[j] itself")).toEqual("that the creation itself");
  });

});