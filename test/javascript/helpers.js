// Helper functions to load and expose JavaScript functions for testing
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create a shared global context for all JavaScript files
const globalContext = {
  // Add jQuery and other globals here
  $: global.$,
  jQuery: global.jQuery,
  Object: global.Object,
  console: global.console,
  word_width: global.word_width
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
    'calculateInputWidth', 'mvPassageReviewHandleInput', 'mvMirrorNextInput',
    'mvDisplayPassageForReview', 'buildVerseBlank'
  ];
  
  // Create a function that executes in the global context
  const executeCode = new Function(...Object.keys(globalContext), 'context', `
    // Variables used in the library that need to be declared
    var book_index, possibilities, i, lang_, bi, vs_start, vs_end;
    
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
  
  // Execute with the global context
  executeCode(...Object.values(globalContext), context);
  
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