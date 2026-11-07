import { describe, it, expect, vi } from 'vitest';
import { JSDOM } from 'jsdom';
import fs from 'fs';

const jquery = fs.readFileSync('public/api/swagger-ui/lib/jquery-1.8.0.min.js', 'utf8');
const source = fs.readFileSync('app/assets/javascripts/memverse_passage_review.js', 'utf8');

describe('Passage queue', () => {
  it.each([true, false])('preserves passage identity and safe labels (Heritage: %s)', (heritage) => {
    const dom = new JSDOM(`<body><details class="${heritage ? 'heritage-passage-picker' : ''}"><div class="upcoming-passages"></div></details></body>`, { runScripts: 'outside-only' });
    dom.window.eval(jquery);
    dom.window.eval(source);
    const state = dom.window.reviewState;
    state.autoAdvancePassage = vi.fn();
    dom.window.$.getJSON = (_url, callback) => callback([{ id: 42, ref: 'Psalm 23:1–6' }, { id: 43, ref: '<b>John</b>' }]);
    state.initialize();
    const items = dom.window.document.querySelectorAll('.upcoming-verse-ref');
    expect(items.length).toBe(2);
    expect(items[0].id).toBe('42');
    expect(items[0].textContent).toBe('Psalm 23:1–6');
    expect(items[1].textContent).toBe('<b>John</b>');
    expect(items[1].querySelector('b')).toBeNull();
    expect(items[0].querySelector('button')?.type).toBe(heritage ? 'button' : undefined);
    expect(state.autoAdvancePassage).toHaveBeenCalledOnce();
    dom.window.close();
  });
});
