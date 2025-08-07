import { describe, it, expect } from 'vitest';
import { memverse } from './helpers.js';

describe("mnemonic", () => {
  it("works for English", () => {
    expect(memverse.mnemonic("'There is therefore now no condemnation'!")).toEqual("'T i t n n c'!");
  });

  it("works for Korean", () => {
    expect(memverse.mnemonic("말씀하시되 나를 따라오라 내가 너희를 사람을 낚는 어부가 되게 하리라 하시니")).toEqual("ᄆᄊᄒᄉᄃ ᄂᄅ ᄄᄅᄋᄅ ᄂᄀ ᄂᄒᄅ ᄉᄅᄋ ᄂᄂ ᄋᄇᄀ ᄃᄀ ᄒᄅᄅ ᄒᄉᄂ");
  });

  it("works for other languages", () => {
    expect(memverse.mnemonic("áâ αβξδεφγη 鄕札")).toEqual("á α 鄕");
  });
});