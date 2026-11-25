import { readFileSync } from 'node:fs';
import { afterEach, describe, expect, it, vi } from 'vitest';

const source = readFileSync('app/assets/javascripts/memverse_passage_review.js', 'utf8');
const review = new Function(source + '\nreturn reviewState;')();

describe('Passage review scrolling', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    document.body.innerHTML = '';
  });

  function setup(content, reduceMotion = false) {
    document.body.innerHTML = '<section>' + content + '</section>';
    vi.stubGlobal('scrollBy', vi.fn());
    vi.stubGlobal('visualViewport', { height: 600, offsetTop: 40 });
    vi.stubGlobal('matchMedia', () => ({ matches: reduceMotion }));
    return document.querySelector('section');
  }

  it('focuses the next blank without a browser jump before centering it', () => {
    const verse = setup('<span class="passage-rating"></span><input class="blank-word">');
    const input = verse.querySelector('input');
    const focus = vi.spyOn(input, 'focus');
    input.getBoundingClientRect = () => ({ top: 600, height: 20 });
    review.scrollToVerse([verse]);
    expect(focus).toHaveBeenCalledWith({ preventScroll: true });
    expect(window.scrollBy.mock.calls).toEqual([[{ top: 270, behavior: 'smooth' }]]);
  });

  it('centers the rating after recall and respects reduced motion', () => {
    const verse = setup('<span class="passage-rating"></span>', true);
    verse.firstChild.getBoundingClientRect = () => ({ top: 80, height: 20 });
    review.scrollToVerse([verse]);
    expect(window.scrollBy.mock.calls).toEqual([[{ top: -250, behavior: 'instant' }]]);
  });

  it('leaves a centered target and an empty selection alone', () => {
    const verse = setup('<span class="passage-rating"></span>');
    verse.firstChild.getBoundingClientRect = () => ({ top: 348, height: 20 });
    review.scrollToVerse([verse]);
    review.scrollToVerse([]);
    expect(window.scrollBy).not.toHaveBeenCalled();
  });
});
