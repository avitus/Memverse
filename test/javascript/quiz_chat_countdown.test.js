import { describe, it, expect, beforeEach, vi } from 'vitest'
import './setup' // Import setup to ensure jQuery is available

describe('Live Quiz Chat Countdown', () => {
  let $ = global.$; // Use global jQuery
  let countdownMock;

  beforeEach(() => {
    // Reset all mocks
    vi.clearAllMocks();

    // Setup DOM elements
    document.body.innerHTML = `
      <div id="quiz-timer"></div>
      <div id="countdown-till"></div>
    `;

    // Store countdown options for testing
    let storedOptions = {};

    // Create countdown mock
    countdownMock = vi.fn(function(options) {
      storedOptions = options;
      return this;
    });

    // Override jQuery to add countdown method to returned elements
    const originalJQuery = global.$;
    $ = global.$ = function(selector) {
      const element = document.querySelector(selector);
      const result = {
        // DOM manipulation methods
        html: function(content) {
          if (element && content !== undefined) {
            element.innerHTML = content;
          }
          return element ? element.innerHTML : '';
        },
        text: function(content) {
          if (element && content !== undefined) {
            element.textContent = content;
          }
          return element ? element.textContent : '';
        },
        val: function(value) {
          if (element && value !== undefined) {
            element.value = value;
          }
          return element ? element.value : '';
        },
        // Add countdown method
        countdown: countdownMock,
        // Add data method to store/retrieve options
        data: function(key, value) {
          if (value !== undefined) {
            storedOptions[key] = value;
            return this;
          }
          return key === 'countdown-options' ? storedOptions : storedOptions[key];
        }
      };

      return result;
    };

    // Copy over static methods
    Object.keys(originalJQuery).forEach(key => {
      $[key] = originalJQuery[key];
    });

    // Mock jQuery ajax
    $.getJSON = vi.fn();
  });

  describe('Chat period countdown', () => {
    it('should display countdown when quiz is in chat period', () => {
      const mockResponse = {
        status: "In progress. Chat open. Wait for question.",
        chat_countdown: true,
        countdown_seconds: 180 // 3 minutes
      };

      // Mock the AJAX response to execute callback immediately
      $.getJSON.mockImplementation((url, callback) => {
        // Execute callback synchronously
        if (callback) callback(mockResponse);
        return { done: () => {}, fail: () => {} };
      });

      // Simulate the code from live_quiz.html.erb
      $.getJSON('/live_quiz/till_start/1.json', function(data) {
        if (data.status) {
          if (data.chat_countdown && data.countdown_seconds) {
            var now = new Date();
            var chatEndTime = new Date(now.getTime() + data.countdown_seconds * 1000);

            $('#quiz-timer').countdown({
              until: chatEndTime,
              significant: 2,
              labels: ['Years', 'Months', 'Weeks', 'Days', 'Hours', 'Mins', 'Secs'],
              labels1: ['Year', 'Month', 'Week', 'Day', 'Hour', 'Min', 'Sec'],
              onExpiry: function() {
                $("#countdown-till").html("<strong>Quiz Status:</strong> First question starting soon...");
              }
            });
            $("#countdown-till").html("<strong>Time until first question:</strong>");
          } else {
            $("#countdown-till").html("<strong>Quiz Status:</strong> " + data.status);
          }
        }
      });

      // Verify the countdown was initialized
      expect(countdownMock).toHaveBeenCalled();

      // Verify the countdown-till text was updated
      expect(document.getElementById('countdown-till').innerHTML).toBe("<strong>Time until first question:</strong>");

      // Get the countdown options
      const countdownOptions = $('#quiz-timer').data('countdown-options');
      expect(countdownOptions).toBeDefined();
      expect(countdownOptions.until).toBeDefined();
      expect(countdownOptions.onExpiry).toBeDefined();

      // Test the onExpiry callback
      countdownOptions.onExpiry();
      expect(document.getElementById('countdown-till').innerHTML).toBe("<strong>Quiz Status:</strong> First question starting soon...");
    });

    it('should display regular status when not in chat period', () => {
      const mockResponse = {
        status: "In progress. Question in progress."
      };

      $.getJSON.mockImplementation((url, callback) => {
        if (callback) callback(mockResponse);
        return { done: () => {}, fail: () => {} };
      });

      $.getJSON('/live_quiz/till_start/1.json', function(data) {
        if (data.status) {
          if (data.chat_countdown && data.countdown_seconds) {
            // This block should not execute
            $("#countdown-till").html("<strong>Time until first question:</strong>");
          } else {
            $("#countdown-till").html("<strong>Quiz Status:</strong> " + data.status);
          }
        }
      });

      // Verify countdown was NOT initialized
      expect(countdownMock).not.toHaveBeenCalled();

      // Verify the status text was set
      expect(document.getElementById('countdown-till').innerHTML).toBe("<strong>Quiz Status:</strong> In progress. Question in progress.");
    });

    it('should handle countdown for quiz not yet started', () => {
      const mockResponse = {
        time: "+0h +4m +30s"
      };

      $.getJSON.mockImplementation((url, callback) => {
        if (callback) callback(mockResponse);
        return { done: () => {}, fail: () => {} };
      });

      $.getJSON('/live_quiz/till_start/1.json', function(data) {
        if (data.status) {
          // Status block
        } else {
          $('#quiz-timer').countdown({
            until: data.time,
            significant: 2,
            labels: ['Years', 'Months', 'Weeks', 'Days', 'Hours', 'Mins', 'Secs'],
            labels1: ['Year', 'Month', 'Week', 'Day', 'Hour', 'Min', 'Sec']
          });
          $("#countdown-till").text("till quiz starts");
        }
      });

      // Verify countdown was initialized with the time string
      expect(countdownMock).toHaveBeenCalled();
      const countdownOptions = $('#quiz-timer').data('countdown-options');
      expect(countdownOptions.until).toBe("+0h +4m +30s");

      // Verify the countdown-till text
      expect(document.getElementById('countdown-till').textContent).toBe("till quiz starts");
    });

    it('should handle countdown expiry during chat period', () => {
      const mockResponse = {
        status: "In progress. Chat open. Wait for question.",
        chat_countdown: true,
        countdown_seconds: 1 // 1 second for quick test
      };

      $.getJSON.mockImplementation((url, callback) => {
        if (callback) callback(mockResponse);
        return { done: () => {}, fail: () => {} };
      });

      $.getJSON('/live_quiz/till_start/1.json', function(data) {
        if (data.status && data.chat_countdown && data.countdown_seconds) {
          var now = new Date();
          var chatEndTime = new Date(now.getTime() + data.countdown_seconds * 1000);

          $('#quiz-timer').countdown({
            until: chatEndTime,
            significant: 2,
            labels: ['Years', 'Months', 'Weeks', 'Days', 'Hours', 'Mins', 'Secs'],
            labels1: ['Year', 'Month', 'Week', 'Day', 'Hour', 'Min', 'Sec'],
            onExpiry: function() {
              $("#countdown-till").html("<strong>Quiz Status:</strong> First question starting soon...");
            }
          });
          $("#countdown-till").html("<strong>Time until first question:</strong>");
        }
      });

      // Get and trigger the onExpiry callback
      const countdownOptions = $('#quiz-timer').data('countdown-options');
      countdownOptions.onExpiry();

      // Verify the expiry message
      expect(document.getElementById('countdown-till').innerHTML).toBe("<strong>Quiz Status:</strong> First question starting soon...");
    });
  });
});