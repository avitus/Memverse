import { describe, it, expect, beforeEach, vi } from 'vitest';
import fs from 'fs';
const source = fs.readFileSync('app/assets/javascripts/heritage.js', 'utf8');

new Function(source)();

it('searches a suggested passage without adding it to the account', () => {
  document.body.innerHTML = '<input id="js_flex-verse-search"><button data-verse-suggestion="Psalm 23"><strong>Psalm 23</strong></button>';
  globalThis.flexversesearch = vi.fn();
  try {
    document.querySelector('strong').click();
    expect(globalThis.flexversesearch).toHaveBeenCalledWith('Psalm 23');
    expect(document.activeElement.value).toBe('Psalm 23');
  } finally { delete globalThis.flexversesearch; }
});

describe('Heritage authentication enhancements', () => {
  beforeEach(() => {
    document.body.innerHTML = '<form class="heritage-auth-form"><input id="user_password" type="password"><input id="user_password_confirmation" type="password"><button type="button" data-password-toggle="user_password" aria-pressed="false">Show</button></form>';
  });
  it('shows and masks the password without changing its value', () => {
    const input = document.getElementById('user_password'); input.value = 'SampleOnly123';
    const button = document.querySelector('button'); button.click();
    expect(input.type).toBe('text'); expect(input.value).toBe('SampleOnly123'); expect(button.getAttribute('aria-pressed')).toBe('true');
    button.click(); expect(input.type).toBe('password'); expect(button.textContent).toBe('Show');
  });
  it('keeps mismatched passwords from submission and recovers after correction', () => {
    document.dispatchEvent(new Event('DOMContentLoaded'));
    const password = document.getElementById('user_password'), confirmation = document.getElementById('user_password_confirmation');
    password.value = 'SampleOnly123'; confirmation.value = 'Different123'; confirmation.dispatchEvent(new Event('input'));
    expect(confirmation.validity.customError).toBe(true);
    confirmation.value = password.value; confirmation.dispatchEvent(new Event('input'));
    expect(confirmation.validity.customError).toBe(false);
  });
});

it('reveals the onboarding review action after five saved additions', () => {
  const originalJQuery = globalThis.$;
  const callbacks = {};
  let prompts = 0;
  function stub(selector) {
    const chain = new Proxy({}, { get: (_, key) => {
      if (key === 'ready') return callback => { callback(); return chain; };
      if (key === 'fadeIn') return () => { if (selector === '#start-memorizing') prompts++; return chain; };
      if (key === 'on') return (event, target, callback) => { callbacks[event] = callback; return chain; };
      return () => chain;
    } });
    if (typeof selector === 'function') selector();
    return chain;
  }
  globalThis.$ = stub;
  document.body.className = 'mv-heritage';
  try {
    new Function(fs.readFileSync('app/assets/javascripts/memverse_quick_start.js', 'utf8'))();
    new Function(source)();
    callbacks['ajax:success'].call({}, { detail: [{ msg: 'Error' }] });
    expect(prompts).toBe(0);
    for (let count = 0; count < 4; count++) callbacks['ajax:success'].call({}, { detail: [{ msg: 'Success' }] });
    expect(prompts).toBe(0);
    callbacks['ajax:success'].call({}, { detail: [{ msg: 'Success' }] });
    expect(prompts).toBe(1);
  } finally {
    globalThis.$ = originalJQuery;
    document.body.className = '';
  }
});

describe('Heritage landing Scripture practice', () => {
  beforeEach(() => {
    document.body.innerHTML = '<button data-demo-start>Begin</button><div data-demo-reading>Read</div><div data-demo-exercise hidden><input id="heritage-demo-answer"><button data-demo-reveal>Reveal the word</button><span data-demo-status role="status"></span><a data-demo-continue hidden>Continue</a></div>';
    document.dispatchEvent(new Event('DOMContentLoaded'));
  });
  it('opens keyboard practice and recognizes a recalled word', () => {
    document.querySelector('[data-demo-start]').click();
    const answer = document.getElementById('heritage-demo-answer');
    expect(document.querySelector('[data-demo-reading]').hidden).toBe(true);
    expect(document.querySelector('[data-demo-exercise]').hidden).toBe(false);
    expect(document.activeElement).toBe(answer);
    answer.value = ' Shepherd ';
    answer.dispatchEvent(new Event('input'));
    expect(document.querySelector('[data-demo-status]').textContent).toContain('Correct');
    expect(document.querySelector('[data-demo-continue]').hidden).toBe(false);
    answer.value = 'wrong'; answer.dispatchEvent(new Event('input'));
    expect(document.querySelector('[data-demo-continue]').hidden).toBe(true);
  });
  it('does not count revealing the word as correct recall', () => {
    const reveal = document.querySelector('[data-demo-reveal]');
    reveal.click();
    expect(document.getElementById('heritage-demo-answer').value).toBe('shepherd');
    expect(document.querySelector('[data-demo-status]').textContent).not.toContain('Correct');
    expect(document.querySelector('[data-demo-continue]').hidden).toBe(true);
    reveal.click();
    expect(document.getElementById('heritage-demo-answer').value).toBe('');
  });
});
