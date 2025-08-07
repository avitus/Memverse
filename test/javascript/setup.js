// Setup file for Vitest tests
// This file runs before each test file

// Mock Object.values for older environments
if (!Object.values) {
  Object.values = function(obj) {
    return Object.keys(obj).map(function(key) {
      return obj[key];
    });
  };
}

// Create a mock jQuery element
const mockJQueryElement = {
  length: 0,
  val: function() { return ''; },
  text: function(text) { 
    if (text !== undefined) return this;
    return ''; 
  },
  html: function() { return ''; },
  hide: function() { return this; },
  show: function() { return this; },
  fadeIn: function() { return this; },
  fadeOut: function() { return this; },
  css: function() { return this; },
  attr: function(name, value) { 
    if (value !== undefined) return this;
    return this; // Return this for chaining
  },
  addClass: function() { return this; },
  removeClass: function() { return this; },
  hasClass: function() { return false; },
  on: function() { return this; },
  off: function() { return this; },
  trigger: function() { return this; },
  append: function() { return this; },
  prepend: function() { return this; },
  width: function() { return 100; }
};

// Mock jQuery selector function
const jQuerySelector = function(selector) {
  // Return a mock jQuery element that supports chaining
  return Object.create(mockJQueryElement);
};

// Add jQuery static methods
Object.assign(jQuerySelector, {
  extend: Object.assign,
  trim: (str) => str ? str.trim() : '',
  parseJSON: JSON.parse,
  ajax: () => Promise.resolve(),
  get: () => Promise.resolve(),
  post: () => Promise.resolve(),
  getJSON: () => Promise.resolve({}),
  each: (arr, fn) => {
    if (Array.isArray(arr)) {
      for (let i = 0; i < arr.length; i++) {
        if (fn(i, arr[i]) === false) break;
      }
    } else {
      const keys = Object.keys(arr);
      for (let i = 0; i < keys.length; i++) {
        if (fn(keys[i], arr[keys[i]]) === false) break;
      }
    }
  },
  map: (arr, fn) => {
    if (Array.isArray(arr)) {
      return arr.map((item, index) => fn(item, index));
    }
    return [];
  },
  inArray: (value, array) => array.indexOf(value),
  isArray: Array.isArray,
  isFunction: (fn) => typeof fn === 'function',
  isPlainObject: (obj) => obj && typeof obj === 'object' && obj.constructor === Object,
  fn: mockJQueryElement
});

// Mock jQuery with commonly used functions
global.$ = global.jQuery = jQuerySelector;

// Add any other global mocks or setup here

// Mock word_width function for testing
global.word_width = function(word) {
  // Return width based on actual word to match test expectations
  const widths = {
    'beginning': 82,
    'created': 63,
    'heavens': 72,
    'earth': 43
  };
  return widths[word] || word.length * 8;
};

// Add parseJSON to jQuery if not present
if (!jQuerySelector.parseJSON) {
  jQuerySelector.parseJSON = JSON.parse;
}