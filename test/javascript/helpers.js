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
    'calculate_levenshtein_distance', 'word_width'
  ];
  
  // Create a function that executes in the global context
  const executeCode = new Function(...Object.keys(globalContext), 'context', `
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
  `);
  
  // Execute with the global context
  executeCode(...Object.values(globalContext), context);
  
  // Also make functions available globally
  Object.assign(globalContext, context);
  
  return context;
}

// Load the main library files
export const memverseLib = loadJavaScriptFile('memverse_lib.js');
export const memverse = loadJavaScriptFile('memverse.js');
export const memverseAccuracy = loadJavaScriptFile('memverse_accuracy_test.js');
export const liveQuiz = loadJavaScriptFile('live_quiz.js');

// Override word_width after loading libraries
globalContext.word_width = global.word_width;
if (memverseLib.word_width) {
  memverseLib.word_width = global.word_width;
}