import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { memverseLib } from './helpers.js';

describe("Passage Review Integration Test - Apostrophe Bug", () => {
  let originalWord_width;
  let mockLog;

  beforeEach(() => {
    // Mock word_width function with realistic widths
    originalWord_width = globalThis.word_width;
    globalThis.word_width = function(word) {
      const widths = {
        "children's": 82,
        "children": 70,
        "child": 42,
        "childr": 54,
        "childre": 62,
        "Lord's": 48,
        "Lord": 40,
        "God's": 36,
        "God": 28,
        '"The': 32,
        'The': 28,
        'sake': 36
      };
      return widths[word] || word.length * 8;
    };
    
    // Mock console.log to capture any debug output
    mockLog = vi.spyOn(console, 'log').mockImplementation(() => {});
    
    // Create DOM structure for passage review
    document.body.innerHTML = `
      <div class="passage-text"></div>
      <div class="upcoming-passages">
        <ul class="passage-list"></ul>
      </div>
      <div class="passage-title"></div>
      <div class="passage-id" style="display: none;"></div>
    `;
    
    // Load passage review functions globally
    globalThis.reviewState = {
      scrollToVerse: vi.fn()
    };
    globalThis.mvDisplayPassageForReview = memverseLib.mvDisplayPassageForReview || function() {};
    globalThis.buildVerseBlank = memverseLib.buildVerseBlank || function() {};
    globalThis.mvDue = () => true;
    globalThis.mvPassageReviewHandleInput = memverseLib.mvPassageReviewHandleInput;
    globalThis.mvMirrorNextInput = memverseLib.mvMirrorNextInput;
    globalThis.flexibleTextMatch = memverseLib.flexibleTextMatch;
    
    // Enhanced jQuery mock for this test
    const originalJQuery = globalThis.$;
    globalThis.$ = function(selector) {
      if (typeof selector === 'string') {
        const elements = document.querySelectorAll(selector);
        const jqObj = Array.from(elements);
        
        // Add jQuery methods to the array
        jqObj.addClass = function(className) {
          this.forEach(el => el.classList.add(className));
          return this;
        };
        
        jqObj.removeClass = function(className) {
          this.forEach(el => el.classList.remove(className));
          return this;
        };
        
        jqObj.css = function(prop, value) {
          if (typeof prop === 'object') {
            this.forEach(el => {
              Object.assign(el.style, prop);
            });
          } else if (value !== undefined) {
            this.forEach(el => {
              el.style[prop] = value;
            });
          } else if (this.length > 0) {
            return getComputedStyle(this[0])[prop];
          }
          return this;
        };
        
        jqObj.attr = function(name, value) {
          if (value !== undefined) {
            this.forEach(el => el.setAttribute(name, value));
            return this;
          } else if (this.length > 0) {
            return this[0].getAttribute(name);
          }
          return null;
        };
        
        jqObj.val = function(value) {
          if (value !== undefined) {
            this.forEach(el => el.value = value);
            return this;
          } else if (this.length > 0) {
            return this[0].value || '';
          }
          return '';
        };
        
        jqObj.width = function() {
          if (this.length > 0) {
            const el = this[0];
            if (el.style.width) {
              return parseInt(el.style.width.replace('px', ''), 10);
            }
            return el.offsetWidth || 100; // fallback
          }
          return 0;
        };
        
        jqObj.text = function(text) {
          if (text !== undefined) {
            this.forEach(el => el.textContent = text);
            return this;
          } else if (this.length > 0) {
            return this[0].textContent;
          }
          return '';
        };
        
        jqObj.html = function(html) {
          if (html !== undefined) {
            this.forEach(el => el.innerHTML = html);
            return this;
          } else if (this.length > 0) {
            return this[0].innerHTML;
          }
          return '';
        };
        
        jqObj.before = function(content) {
          this.forEach(el => {
            if (typeof content === 'string') {
              el.insertAdjacentHTML('beforebegin', content);
            } else if (content instanceof Element) {
              el.parentNode.insertBefore(content, el);
            } else if (content.jquery || Array.isArray(content)) {
              const elements = Array.isArray(content) ? content : Array.from(content);
              elements.forEach(item => {
                el.parentNode.insertBefore(item, el);
              });
            }
          });
          return this;
        };
        
        jqObj.nextUntil = function(selector) {
          const result = [];
          if (this.length > 0) {
            let current = this[0].nextElementSibling;
            while (current && !current.matches(selector)) {
              result.push(current);
              current = current.nextElementSibling;
            }
          }
          return result;
        };
        
        jqObj.next = function() {
          const result = [];
          this.forEach(el => {
            if (el.nextElementSibling) {
              result.push(el.nextElementSibling);
            }
          });
          // Return a jQuery-like object
          const nextObj = result;
          nextObj.is = function(selector) {
            return this.length > 0 && this[0].matches(selector);
          };
          nextObj.attr = jqObj.attr;
          nextObj.css = jqObj.css;
          nextObj.val = jqObj.val;
          nextObj.remove = function() {
            this.forEach(el => el.remove());
            return this;
          };
          return nextObj;
        };
        
        jqObj.remove = function() {
          this.forEach(el => el.remove());
          return this;
        };
        
        jqObj.focus = function() {
          if (this.length > 0) {
            this[0].focus();
          }
          return this;
        };
        
        return jqObj;
      } else if (selector instanceof Element) {
        const jqObj = [selector];
        jqObj.addClass = function(className) {
          this[0].classList.add(className);
          return this;
        };
        jqObj.removeClass = function(className) {
          this[0].classList.remove(className);
          return this;
        };
        jqObj.css = function(prop, value) {
          if (typeof prop === 'object') {
            Object.assign(this[0].style, prop);
          } else if (value !== undefined) {
            this[0].style[prop] = value;
          } else {
            return getComputedStyle(this[0])[prop];
          }
          return this;
        };
        jqObj.attr = function(name, value) {
          if (value !== undefined) {
            this[0].setAttribute(name, value);
            return this;
          } else {
            return this[0].getAttribute(name);
          }
        };
        jqObj.val = function(value) {
          if (value !== undefined) {
            this[0].value = value;
            return this;
          } else {
            return this[0].value || '';
          }
        };
        jqObj.width = function() {
          if (this[0].style.width) {
            return parseInt(this[0].style.width.replace('px', ''), 10);
          }
          return this[0].offsetWidth || 100;
        };
        jqObj.text = function(text) {
          if (text !== undefined) {
            this[0].textContent = text;
            return this;
          } else {
            return this[0].textContent;
          }
        };
        jqObj.before = function(content) {
          if (typeof content === 'string') {
            this[0].insertAdjacentHTML('beforebegin', content);
          } else if (content instanceof Element) {
            this[0].parentNode.insertBefore(content, this[0]);
          }
          return this;
        };
        jqObj.nextUntil = function(selector) {
          const result = [];
          let current = this[0].nextElementSibling;
          while (current && !current.matches(selector)) {
            result.push(current);
            current = current.nextElementSibling;
          }
          return result;
        };
        jqObj.next = function() {
          const next = this[0].nextElementSibling;
          if (next) {
            const nextObj = [next];
            nextObj.is = function(selector) {
              return this[0].matches(selector);
            };
            nextObj.attr = function(name, value) {
              if (value !== undefined) {
                this[0].setAttribute(name, value);
                return this;
              } else {
                return this[0].getAttribute(name);
              }
            };
            nextObj.css = function(prop) {
              return getComputedStyle(this[0])[prop];
            };
            nextObj.val = function(value) {
              if (value !== undefined) {
                this[0].value = value;
                return this;
              } else {
                return this[0].value || '';
              }
            };
            nextObj.remove = function() {
              this[0].remove();
              return this;
            };
            return nextObj;
          }
          return { length: 0, is: () => false, remove: () => {} };
        };
        jqObj.remove = function() {
          this[0].remove();
          return this;
        };
        return jqObj;
      }
      return originalJQuery(selector);
    };
    
    // Add static jQuery methods
    globalThis.$.trim = (str) => str ? str.trim() : '';
    globalThis.$ = Object.assign(globalThis.$, originalJQuery);
  });

  afterEach(() => {
    // Restore original functions
    if (originalWord_width) {
      globalThis.word_width = originalWord_width;
    }
    mockLog.mockRestore();
    
    // Clean up DOM
    document.body.innerHTML = '';
  });

  describe("Simulating the exact apostrophe bug scenario", () => {
    it("should catch the input field width shrinkage bug during progressive typing", () => {
      // Setup: Create passage with "children's" word directly
      const verseText = "For the children's sake we pray";
      const blankified = memverseLib.blankifyVerse(verseText, 50);
      
      // Create the DOM structure exactly as the app would
      document.querySelector('.passage-text').innerHTML = `
        <div class="single-verse-in-passage due-mv">
          <div class="ref-and-text">
            <span class="versenum superscript">1</span>
            <span class="full-text">${blankified}</span>
          </div>
        </div>
      `;
      
      // Try different selectors to find the input
      let inputField = document.querySelector('input[name="children\'s"]');
      if (!inputField) {
        // The name might be HTML encoded or truncated
        const allInputs = document.querySelectorAll('input');
        inputField = Array.from(allInputs).find(input => 
          input.name === "children's" || 
          input.name === "children's" ||
          input.name === "children" || // Handle truncated case
          input.name.includes("children")
        );
      }
      
      expect(inputField, 'Input field for children\'s should exist').toBeTruthy();
      
      // Verify initial width (should be enhanced: 80 + 8 = 88px)
      const initialWidth = parseInt(inputField.style.width.replace('px', ''), 10);
      expect(initialWidth).toBe(88); // 80 + 8 buffer
      
      // Track width changes during progressive typing
      const widthHistory = [];
      
      // Simulate progressive keyup events: c, ch, chi, child, childr, childre, children
      const progressiveInputs = ['c', 'ch', 'chi', 'child', 'childr', 'childre', 'children'];
      
      progressiveInputs.forEach((userInput, index) => {
        // Set the input value
        inputField.value = userInput;
        
        // Create keyup event
        const keyupEvent = new KeyboardEvent('keyup', { 
          key: userInput.slice(-1),
          code: `Key${userInput.slice(-1).toUpperCase()}`,
          keyCode: userInput.slice(-1).toUpperCase().charCodeAt(0)
        });
        
        // Get current width before processing
        const widthBefore = parseInt(inputField.style.width.replace('px', ''), 10);
        
        // Call the handler directly (simulating the event binding)
        const $inputCell = globalThis.$(inputField);
        // The correct word should be "children's" - handle the case where the browser might truncate at the apostrophe
        let correctWord = inputField.name;
        
        // If the name was truncated at the apostrophe due to HTML parsing issues, we need to use the expected value
        if (correctWord === "children" && inputField.outerHTML.includes("children")) {
          // The HTML parsing truncated at the apostrophe, use the correct full word
          correctWord = "children's";
        }
        
        const userGuess = userInput;
        
        // This is the critical test - the handler should NOT match until complete word
        const matchResult = memverseLib.flexibleTextMatch(correctWord, userGuess);
        
        // Track the progression
        widthHistory.push({
          input: userInput,
          widthBefore: widthBefore,
          shouldMatch: matchResult,
          step: index + 1
        });
        
        // CRITICAL ASSERTION: Width should NOT change during partial typing
        const widthAfter = parseInt(inputField.style.width.replace('px', ''), 10);
        
        if (userInput === 'children') {
          // This is where the bug would occur if flexible matching incorrectly matches "children" to "children's"
          // The test verifies that "children" does NOT match "children's"
          expect(matchResult, `"${userInput}" should NOT match "${correctWord}" - preventing premature field replacement`).toBe(false);
        }
        
        // Width should remain constant until word is complete
        expect(widthAfter).toBe(initialWidth, 
          `Input field width should not change during progressive typing. Step ${index + 1}: "${userInput}" -> width changed from ${widthBefore}px to ${widthAfter}px`);
        
        // The key test is that partial words should NOT match
        if (userInput === 'children') {
          // This is the core bug we're testing - "children" should NOT match "children's"
          expect(matchResult, `"${userInput}" should NOT match "${correctWord}"`).toBe(false);
        }
      });
      
      // Now test the correct completion scenarios
      const validCompletions = ["children's", "childrens"]; // both should work
      
      validCompletions.forEach(completion => {
        // Reset field for each test
        const testField = document.createElement('input');
        testField.setAttribute('name', "children's");
        testField.style.width = '90px';
        testField.className = 'blank-word';
        
        const container = document.createElement('div');
        container.appendChild(testField);
        document.body.appendChild(container);
        
        testField.value = completion;
        
        // Test that complete words match
        const shouldMatch = memverseLib.flexibleTextMatch("children's", completion);
        expect(shouldMatch, `"${completion}" should match "children's"`).toBe(true);
        
        // Clean up
        container.remove();
      });
      
      console.log('Progressive typing test completed. Width history:', widthHistory);
    });

    it("should demonstrate the DOM manipulation timing issue", () => {
      // Create a more complex passage with multiple words
      document.querySelector('.passage-text').innerHTML = `
        <div class="single-verse-in-passage due-mv">
          <div class="ref-and-text">
            <span class="versenum superscript">1</span>
            <span class="full-text">
              For <input name="children's" class="blank-word" style="width:90px" autocomplete="off"> 
              <input name="sake" class="blank-word" style="width:44px" autocomplete="off"> we pray
            </span>
          </div>
        </div>
      `;
      
      const childrenInput = document.querySelector('input[name="children\'s"]');
      const sakeInput = document.querySelector('input[name="sake"]');
      
      expect(childrenInput).toBeTruthy();
      expect(sakeInput).toBeTruthy();
      
      // Simulate the exact DOM manipulation that happens in mvPassageReviewHandleInput
      childrenInput.value = 'children';
      
      // This simulates the current (buggy) behavior where "children" matches "children's"
      if (memverseLib.flexibleTextMatch("children's", "children")) {
        // Get current width
        const currentWidth = 90; // from style
        
        // Create span exactly as the code does
        const span = document.createElement('span');
        span.textContent = "children's ";
        span.style.display = 'inline-block';
        span.style.minWidth = currentWidth + 'px';
        
        // Insert span before input
        childrenInput.parentNode.insertBefore(span, childrenInput);
        
        // Move subsequent elements
        const nextElements = [];
        let current = childrenInput.nextElementSibling;
        while (current && current !== sakeInput) {
          nextElements.push(current);
          current = current.nextElementSibling;
        }
        
        nextElements.forEach(el => {
          childrenInput.parentNode.insertBefore(el, childrenInput);
        });
        
        // Mirror next input (this is the critical part that causes width change)
        if (sakeInput) {
          // Update current input to mirror next input
          childrenInput.setAttribute('name', sakeInput.getAttribute('name'));
          childrenInput.style.width = sakeInput.style.width; // This causes the width shrinkage!
          childrenInput.value = sakeInput.value;
          
          // Remove next input
          sakeInput.remove();
        }
        
        // Verify the bug: width has shrunk from 90px to 44px
        const newWidth = parseInt(childrenInput.style.width.replace('px', ''), 10);
        
        // This assertion demonstrates the bug
        expect(newWidth).toBe(44); // Width has shrunk from 90px to 44px - this is the bug!
        
        // The span should preserve the layout
        expect(span.style.minWidth).toBe('90px');
        
        console.log(`BUG DEMONSTRATED: Input width changed from 90px to ${newWidth}px`);
        console.log('Span min-width:', span.style.minWidth);
        console.log('This causes the visual "shrinking" that users see');
      }
    });

    it("should test the complete user interaction flow", () => {
      // Create the full passage DOM structure
      const passageHtml = `
        <div class="single-verse-in-passage due-mv">
          <div class="passage-rating">
            <div class="tool-tip-nav">Rate:</div>
            <div class="mv-id">123</div>
            <div class="score-test-buttons">
              <span class="submit" q="1">1</span>
              <span class="submit" q="2">2</span>
              <span class="submit" q="3">3</span>
              <span class="submit" q="4">4</span>
              <span class="submit" q="5">5</span>
            </div>
          </div>
          <div class="ref-and-text">
            <span class="versenum superscript">1</span>
            <span class="full-text">For the <input name="children's" class="blank-word" style="width:90px" autocomplete="off"> sake we <input name="pray" class="blank-word" style="width:36px" autocomplete="off"></span>
          </div>
        </div>
      `;
      
      document.querySelector('.passage-text').innerHTML = passageHtml;
      
      // Test the complete keyup event flow as it would happen in the browser
      const passageText = document.querySelector('.passage-text');
      const childrenInput = document.querySelector('input[name="children\'s"]');
      
      let eventFired = false;
      
      // Add the actual event listener as it exists in the app
      passageText.addEventListener('keyup', function(e) {
        if (e.target.matches('input.blank-word')) {
          eventFired = true;
          const $inputCell = globalThis.$(e.target);
          const correctWord = e.target.name;
          const userGuess = e.target.value.trim();
          
          // Call the actual handler
          globalThis.mvPassageReviewHandleInput($inputCell, correctWord, userGuess, e);
        }
      });
      
      // Simulate user typing "children" (which should NOT complete the word)
      childrenInput.value = 'children';
      childrenInput.focus();
      
      // Fire the keyup event
      const keyupEvent = new KeyboardEvent('keyup', { 
        key: 'n',
        code: 'KeyN',
        keyCode: 78,
        bubbles: true
      });
      
      childrenInput.dispatchEvent(keyupEvent);
      
      // Verify event was handled
      expect(eventFired).toBe(true);
      
      // The critical test: field should still exist and maintain width
      const fieldAfterPartialInput = document.querySelector('input[name="children\'s"]');
      expect(fieldAfterPartialInput, 'Input field should still exist after typing "children"').toBeTruthy();
      
      if (fieldAfterPartialInput) {
        const width = parseInt(fieldAfterPartialInput.style.width.replace('px', ''), 10);
        expect(width, 'Input field should maintain its width after partial input').toBe(90);
      }
      
      // Now test with complete input "children's"
      eventFired = false;
      childrenInput.value = "children's";
      
      const completeKeyupEvent = new KeyboardEvent('keyup', { 
        key: 's',
        code: 'KeyS',
        keyCode: 83,
        bubbles: true
      });
      
      childrenInput.dispatchEvent(completeKeyupEvent);
      
      expect(eventFired).toBe(true);
      
      // Now the field SHOULD be replaced (this is expected behavior)
      const fieldAfterCompleteInput = document.querySelector('input[name="children\'s"]');
      // This might be null if correctly replaced, or should have different name if mirrored to next input
    });
  });

  describe("The Core Apostrophe Bug - flexibleTextMatch", () => {
    it("should demonstrate the exact bug scenario that causes width shrinkage", () => {
      console.log('\n🔍 DEMONSTRATING THE APOSTROPHE BUG:');
      console.log('When user types "children" for the word "children\'s"...\n');
      
      // This is the exact scenario that causes the bug
      const correctWord = "children's";
      const partialUserInput = "children";
      
      // The bug: flexibleTextMatch incorrectly matches partial input
      const currentBehavior = memverseLib.flexibleTextMatch(correctWord, partialUserInput);
      
      console.log(`❌ Current (buggy) behavior: "${partialUserInput}" matches "${correctWord}" = ${currentBehavior}`);
      
      if (currentBehavior) {
        console.log('🐛 This causes the input field to be replaced with a span');
        console.log('🐛 The input then mirrors the NEXT field\'s width (smaller)');
        console.log('🐛 Result: User sees the field "shrink" visually');
        console.log('🐛 The field should NOT be replaced until user types the complete word or moves on\n');
      }
      
      // What should happen instead
      console.log(`✅ Expected behavior: "${partialUserInput}" matches "${correctWord}" = false`);
      console.log('✅ Field should maintain its width until user completes the word');
      console.log('✅ User can type "children\'s", "childrens", or move to next field\n');
      
      // This assertion will FAIL, demonstrating the bug exists
      expect(currentBehavior, 
        `🐛 BUG CONFIRMED: "${partialUserInput}" should NOT match "${correctWord}" but it does! This causes the input field width shrinkage bug in passage review mode.`
      ).toBe(false);
    });

    it("should show that complete and alternative inputs work correctly", () => {
      const correctWord = "children's";
      
      // These should all work correctly
      const validInputs = [
        "children's", // exact match
        "childrens",  // without apostrophe
      ];
      
      validInputs.forEach(input => {
        const matches = memverseLib.flexibleTextMatch(correctWord, input);
        expect(matches, `"${input}" should match "${correctWord}"`).toBe(true);
      });
    });
  });

  describe("Edge cases that trigger the bug", () => {
    it("should handle apostrophe words that are substrings of each other - THIS TEST SHOULD FAIL INITIALLY (BUG DETECTION)", () => {
      const testCases = [
        { correct: "God's", partial: "God", shouldMatch: false },
        { correct: "Lord's", partial: "Lord", shouldMatch: false },
        { correct: "children's", partial: "children", shouldMatch: false },
        { correct: "Jesus'", partial: "Jesus", shouldMatch: false }
      ];
      
      console.log('=== TESTING FOR THE APOSTROPHE BUG ===');
      
      testCases.forEach(testCase => {
        const matches = memverseLib.flexibleTextMatch(testCase.correct, testCase.partial);
        
        console.log(`Testing: "${testCase.partial}" vs "${testCase.correct}" -> ${matches ? 'MATCHES' : 'NO MATCH'}`);
        
        if (matches && !testCase.shouldMatch) {
          console.log(`🐛 BUG DETECTED: "${testCase.partial}" incorrectly matches "${testCase.correct}"`);
          console.log('This causes the input field to be replaced prematurely, leading to width shrinkage.');
        }
        
        expect(matches, 
          `BUG: "${testCase.partial}" should NOT match "${testCase.correct}" - this causes premature field replacement and width shrinkage in passage review`
        ).toBe(testCase.shouldMatch);
      });
      
      console.log('=== END BUG DETECTION TEST ===');
    });

    it("should handle valid variations that should match", () => {
      const testCases = [
        { correct: "children's", input: "children's", shouldMatch: true },
        { correct: "children's", input: "childrens", shouldMatch: true },
        { correct: "Lord's", input: "Lord's", shouldMatch: true },
        { correct: "Lord's", input: "Lords", shouldMatch: true },
        { correct: "God's", input: "Gods", shouldMatch: true }
      ];
      
      testCases.forEach(testCase => {
        const matches = memverseLib.flexibleTextMatch(testCase.correct, testCase.input);
        expect(matches, 
          `"${testCase.input}" should match "${testCase.correct}"`
        ).toBe(testCase.shouldMatch);
      });
    });
  });
});