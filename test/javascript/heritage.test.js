import { describe, it, expect, beforeEach } from 'vitest';
import fs from 'fs';
const source = fs.readFileSync('app/assets/javascripts/heritage.js', 'utf8');

new Function(source)();

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
