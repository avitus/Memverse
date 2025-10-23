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
      obj.forEach((val, idx) => fn.call(val, idx, val));
    } else if (typeof obj === 'object' && obj !== null) {
      Object.keys(obj).forEach(key => fn.call(obj[key], key, obj[key]));
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