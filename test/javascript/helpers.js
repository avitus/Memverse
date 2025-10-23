// Helper functions to load and expose JavaScript functions for testing
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Import setup to ensure jQuery is available
import './setup.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Ensure jQuery is available - import from setup if not already global
if (typeof global.$ === 'undefined' || typeof global.jQuery === 'undefined') {
  console.warn('jQuery not found in global scope, using fallback mock');
  // Create a complete jQuery mock if needed
  const jQueryFallback = function(selector) {
    const obj = {
      _selector: selector,
      val: () => '',
      text: () => '',
      html: () => '',
      attr: () => '',
      prop: () => '',
      css: () => {},
      width: () => 100,
      hide: () => obj,
      show: () => obj,
      remove: () => obj,
      empty: () => obj,
      append: () => obj,
      prepend: () => obj,
      on: () => obj,
      off: () => obj,
      trigger: () => obj,
      focus: () => obj,
      clone: () => obj,
      prependTo: () => obj,
      each: (fn) => obj,
      ready: (fn) => obj,
      get: () => obj,
      eq: () => obj,
      length: 0
    };
    return obj;
  };
  // Add static methods
  jQueryFallback.parseJSON = (str) => JSON.parse(str);
  jQueryFallback.ajax = () => Promise.resolve({});
  jQueryFallback.get = () => Promise.resolve({});
  jQueryFallback.post = () => Promise.resolve({});
  jQueryFallback.getJSON = () => Promise.resolve({});
  jQueryFallback.isFunction = (obj) => typeof obj === 'function';
  jQueryFallback.trim = (str) => (str || '').trim();
  jQueryFallback.each = (obj, fn) => {
    if (Array.isArray(obj)) {
      for (let idx = 0; idx < obj.length; idx++) {
        if (fn.call(obj[idx], idx, obj[idx]) === false) break;
      }
    } else if (typeof obj === 'object' && obj !== null) {
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (fn.call(obj[key], key, obj[key]) === false) break;
      }
    }
    return obj;
  };
  jQueryFallback.inArray = (value, array) => {
    if (!Array.isArray(array)) return -1;
    return array.indexOf(value);
  };
  global.$ = global.$ || jQueryFallback;
  global.jQuery = global.jQuery || jQueryFallback;
}

// Create a shared global context for all JavaScript files
const globalContext = {
  // Add jQuery and other globals here
  $: global.$,
  jQuery: global.jQuery,
  Object: global.Object,
  console: global.console,
  word_width: global.word_width,
  BIBLEBOOKS: global.BIBLEBOOKS
};

// Function to load and evaluate JavaScript files in a shared context
export function loadJavaScriptFile(filePath) {
  const absolutePath = path.join(__dirname, '../../app/assets/javascripts', filePath);
  const content = fs.readFileSync(absolutePath, 'utf8');
  
  // Create a context object to capture the functions
  const context = {};
  
  // List of functions to export
  const functionsToExport = [
    'mnemonic', 'unabbreviate', 'validVerseRef', 'validPassageRef',
    'validChapterRef', 'validSubChapterPassage', 'cleanseVerseText',
    'blankifyVerse', 'parseVerseRef', 'parsePassageRef', 'verseFeedback',
    'accTestState', 'splitByWords', 'BIBLEBOOKS', 'scrub_text',
    'calculate_levenshtein_distance', 'word_width', 'flexibleTextMatch',
    'flexibleTextMatchWithBase', 'calculateInputWidth', 'mvPassageReviewHandleInput',
    'mvMirrorNextInput', 'mvDisplayPassageForReview', 'buildVerseBlank'
  ];
  
  // Filter out any undefined values from globalContext
  const contextKeys = Object.keys(globalContext).filter(key => globalContext[key] !== undefined);
  const contextValues = contextKeys.map(key => globalContext[key]);

  // Debug logging for CI
  if (process.env.CI) {
    console.log('Running in CI environment');
    console.log('Context keys:', contextKeys);
    console.log('Context values defined:', contextValues.map(v => v !== undefined));
  }

  // Create a function that executes in the global context
  // Wrap in try-catch to provide better error messages
  let executeCode;
  try {
    executeCode = new Function(...contextKeys, 'context', `
    // Variables used in the library that need to be declared
    var book_index, possibilities, i, lang_, bi, vs_start, vs_end;

    // Ensure jQuery is available in this execution context
    if (typeof $ === 'undefined' && typeof jQuery !== 'undefined') {
      var $ = jQuery;
    }
    if (typeof jQuery === 'undefined' && typeof $ !== 'undefined') {
      var jQuery = $;
    }

    // Make $ and jQuery available globally for the functions
    if (typeof window !== 'undefined') {
      window.$ = window.$ || $;
      window.jQuery = window.jQuery || jQuery;
    }
    if (typeof global !== 'undefined') {
      global.$ = global.$ || $;
      global.jQuery = global.jQuery || jQuery;
    }
    if (typeof globalThis !== 'undefined') {
      globalThis.$ = globalThis.$ || $;
      globalThis.jQuery = globalThis.jQuery || jQuery;
    }
    
    // Check if word_width is already defined globally and preserve it
    const globalWordWidth = typeof word_width !== 'undefined' ? word_width : null;
    
    ${content}
    
    // Restore global word_width if it was overridden
    if (globalWordWidth && typeof word_width !== 'undefined') {
      word_width = globalWordWidth;
    }
    
    // Export any functions defined
    ${functionsToExport.map(fn => 
      `if (typeof ${fn} !== 'undefined') { context.${fn} = ${fn}; globalThis.${fn} = ${fn}; }`
    ).join('\n')}
    
    // Also export BIBLEBOOKS if it exists
    if (typeof BIBLEBOOKS !== 'undefined') {
      context.BIBLEBOOKS = BIBLEBOOKS;
      globalThis.BIBLEBOOKS = BIBLEBOOKS;
    }
  `);
  } catch (error) {
    console.error('Failed to create executeCode function:', error);
    console.error('Context keys:', contextKeys);
    console.error('File path:', filePath);
    throw error;
  }

  // Execute with the filtered context values
  try {
    executeCode(...contextValues, context);
  } catch (error) {
    console.error('Failed to execute code for file:', filePath);
    console.error('Error:', error);
    throw error;
  }

  // Also make functions available globally
  Object.assign(globalContext, context);

  // Make the required variables available globally for the functions
  if (typeof global !== 'undefined') {
    global.book_index = global.book_index || undefined;
    global.possibilities = global.possibilities || undefined;
    global.i = global.i || undefined;
    global.lang_ = global.lang_ || undefined;
    global.bi = global.bi || undefined;
    global.vs_start = global.vs_start || undefined;
    global.vs_end = global.vs_end || undefined;
  }
  if (typeof globalThis !== 'undefined') {
    globalThis.book_index = globalThis.book_index || undefined;
    globalThis.possibilities = globalThis.possibilities || undefined;
    globalThis.i = globalThis.i || undefined;
    globalThis.lang_ = globalThis.lang_ || undefined;
    globalThis.bi = globalThis.bi || undefined;
    globalThis.vs_start = globalThis.vs_start || undefined;
    globalThis.vs_end = globalThis.vs_end || undefined;
  }
  
  return context;
}

// Load the main library files
loadJavaScriptFile('memverse_lib.js');
loadJavaScriptFile('memverse.js');
loadJavaScriptFile('memverse_accuracy_test.js');
loadJavaScriptFile('live_quiz.js');
loadJavaScriptFile('memverse_passage_review.js');

// Create the memverseLib object with all the functions from globalThis
export const memverseLib = {
  // jQuery is needed by the library functions
  $: globalThis.$ || globalContext.$ || global.$,
  jQuery: globalThis.jQuery || globalContext.jQuery || global.jQuery,
  mnemonic: globalThis.mnemonic || globalContext.mnemonic,
  unabbreviate: globalThis.unabbreviate || globalContext.unabbreviate,
  validVerseRef: globalThis.validVerseRef || globalContext.validVerseRef,
  validPassageRef: globalThis.validPassageRef || globalContext.validPassageRef,
  validChapterRef: globalThis.validChapterRef || globalContext.validChapterRef,
  validSubChapterPassage: globalThis.validSubChapterPassage || globalContext.validSubChapterPassage,
  cleanseVerseText: globalThis.cleanseVerseText || globalContext.cleanseVerseText,
  blankifyVerse: globalThis.blankifyVerse || globalContext.blankifyVerse,
  parseVerseRef: globalThis.parseVerseRef || globalContext.parseVerseRef,
  parsePassageRef: globalThis.parsePassageRef || globalContext.parsePassageRef,
  verseFeedback: globalThis.verseFeedback || globalContext.verseFeedback,
  accTestState: globalThis.accTestState || globalContext.accTestState,
  splitByWords: globalThis.splitByWords || globalContext.splitByWords,
  BIBLEBOOKS: globalThis.BIBLEBOOKS || globalContext.BIBLEBOOKS,
  scrub_text: globalThis.scrub_text || globalContext.scrub_text,
  calculate_levenshtein_distance: globalThis.calculate_levenshtein_distance || globalContext.calculate_levenshtein_distance,
  word_width: global.word_width,
  flexibleTextMatch: globalThis.flexibleTextMatch || globalContext.flexibleTextMatch,
  flexibleTextMatchWithBase: globalThis.flexibleTextMatchWithBase || globalContext.flexibleTextMatchWithBase,
  calculateInputWidth: globalThis.calculateInputWidth || globalContext.calculateInputWidth,
  mvPassageReviewHandleInput: globalThis.mvPassageReviewHandleInput || globalContext.mvPassageReviewHandleInput,
  mvMirrorNextInput: globalThis.mvMirrorNextInput || globalContext.mvMirrorNextInput,
  mvDisplayPassageForReview: globalThis.mvDisplayPassageForReview || globalContext.mvDisplayPassageForReview,
  buildVerseBlank: globalThis.buildVerseBlank || globalContext.buildVerseBlank
};

// Export other objects
export const memverse = globalContext;
export const memverseAccuracy = globalContext;
export const liveQuiz = globalContext;