setupMCQ = function(q_option_a, q_option_b, q_option_c, q_option_d, mc_answer, q_num){
	var q = "q" + q_num + "_";
	output = ["<ul class='mcq' style='margin-top: 1.5rem;'>",
				"<li><input type='radio' name='mcq' value='a' id='"+q+"opt_a' /> <label for='"+q+"opt_a'>(A) " + q_option_a + "</label></li>",
				"<li><input type='radio' name='mcq' value='b' id='"+q+"opt_b' /> <label for='"+q+"opt_b'>(B) " + q_option_b + "</label></li>",
				"<li><input type='radio' name='mcq' value='c' id='"+q+"opt_c' /> <label for='"+q+"opt_c'>(C) " + q_option_c + "</label></li>",
				"<li><input type='radio' name='mcq' value='d' id='"+q+"opt_d' /> <label for='"+q+"opt_d'>(D) " + q_option_d + "</label></li>",
			"</ul>",
			"<input type='submit' value='Answer!' id='submit-answer' class='button-link'>"]

	return output.join("");
};

/******************************************************************************
 * Calculate Levenshtein distance
 ******************************************************************************/
function calculate_levenshtein_distance(s, t) {
  var m = s.length + 1, n = t.length + 1;
  var i, j;

  // for all i and j, d[i,j] will hold the Levenshtein distance between
  // the first i words of s and the first j words of t;
  // note that d has (m+1)x(n+1) values
  var d = [];

  for (i = 0; i < m; i++) {
	d[i] = [i]; // the distance of any first array to an empty second array
  }
  for (j = 0; j < n; j++) {
	d[0][j] = j; // the distance of any second array to an empty first array
  }

  for (j = 1; j < n; j++) {
	for (i = 1; i < m; i++) {
	  if (s[i - 1] === t[j - 1]) {
		d[i][j] = d[i-1][j-1];           // no operation required
	  } else {
		d[i][j] = Math.min(
					d[i - 1][j] + 1,     // a deletion
					d[i][j - 1] + 1,     // an insertion
					d[i - 1][j - 1] + 1  // a substitution
				  );
	  }
	}
  }

  return d[m - 1][n - 1];
}

/******************************************************************************
 * Score a recitation [Max 10 points]
 ******************************************************************************/
function scoreRecitation(versetext, usertext) {

	var score, msg;

	// Convert to lowercase; remove anything that is not a-z and remove extra spaces
	// Do I need to use unescape because of quotation marks? Time will tell...
	user    = $.trim(usertext.toLowerCase().replace(/[^a-z ]|\s-|\s—/g, '').replace(/\s+/g, " "));
	correct = $.trim(versetext.toLowerCase().replace(/[^a-z ]|\s-|\s—/g, '').replace(/\s+/g, " "));

	if (user == "") {
		alert('Please recite the verse. You clicked "Submit" without any words in the box.')
		return false;
	}

	user_words  = user.split(" ");
	right_words = correct.split(" ");

	score = 10 - (calculate_levenshtein_distance(right_words, user_words));

	if (score < 0) {score = 0;} // Prevents score from being less than 0.

	if (score == 10) {
		msg = "You answered perfectly and scored 10 points! Good job.";
	}
	else if (score >= 1) {
		msg = "Although that wasn't perfect, you still received " + score + " points. Keep trying!";
	}
	else {
		msg = "I'm sorry, but that was not correct.";
	}

	return { score: score, msg: msg };
}

/******************************************************************************
 * Score a reference recall [Max = 10 points]
 ******************************************************************************/
function scoreReference(verseref, userref) {

	var score, msg;

	user    = $.trim(userref.toLowerCase().replace(/\s+/g, " "));
	correct = $.trim(verseref.toLowerCase().replace(/\s+/g, " "));

	// handle corner cases
	// note: lowercase
	user = user.replace(/(song of songs)/i, "song of songs")
			   .replace(/(psalm )/i,        "psalms ");

	correct = correct.replace(/(song of songs)/i, "song of songs")
					 .replace(/(psalm )/i,        "psalms ");

	user_book  = user.substring(0,parseInt(user.lastIndexOf(' '))+1);
	right_book = correct.substring(0,parseInt(correct.lastIndexOf(' '))+1);

	user_chapter  = user.substring(parseInt(user.lastIndexOf(' '))+1,user.indexOf(':'));
	right_chapter = correct.substring(parseInt(correct.lastIndexOf(' '))+1,correct.indexOf(':'));

	user_verse  = user.substring(parseInt(user.indexOf(':'))+1);
	right_verse = correct.substring(parseInt(correct.indexOf(':'))+1);

	if ( user_book == "" || user_chapter == "" || user_verse == "" || user.indexOf(':') == "-1") {
		alert("Please format your reference answer as Book Chapter:Verse (for example, Genesis 1:1-2) and try again.\n\nIf you are unsure of part of the reference, just take your best guess. Thank you!");
		return false;
	}

	score = 0;

	if (user_book    == right_book)    {score = score + 2;}
	if (user_chapter == right_chapter) {score = score + 3;}
	if (user_verse   == right_verse)   {score = score + 5;}

	if (score == 10) {
		msg = "You answered perfectly and scored 10 points! Good job.";
	} else if (score >= 1) {
		msg = "Although that wasn't perfect, you still received " + score + " points. Keep trying! The correct reference was " + verseref + " (you entered " + userref + ").";
	} else {
		msg = "Sorry, but that was not correct. The correct reference was " + verseref + ".";
	}

	return { score: score, msg: msg };
}

/******************************************************************************
 * Score a multiple choice question [Max = 10 points]
 ******************************************************************************/
function scoreMCQ(questionAnswer, userAnswer){ // userAnswer will be a, b, c, or d, unless it's empty
	score = ( userAnswer.toUpperCase() == questionAnswer.toUpperCase() ) ? 10 : -2;
	if ( score == 10 ) {
		msg = "Congratulations; that was perfect!";
	} else {
		msg = "Sorry, but your choice (" + userAnswer.toUpperCase() + ") was not correct. The correct answer was (" + questionAnswer.toUpperCase() + ").";
	}

	return { score: score, msg: msg };
}

/******************************************************************************
 * Score based on question type
 ******************************************************************************/
function getScore(questionAnswer, userAnswer, questionType) {

	switch(questionType) {
		case 'recitation':
			return scoreRecitation(questionAnswer, userAnswer);
		break;

		case 'reference':
			return scoreReference(questionAnswer, userAnswer);
		break;

		case 'mcq':
			return scoreMCQ(questionAnswer, userAnswer);
		break;

		default:
			return 0

	}

}

/******************************************************************************
 * Quiz Schedule Functions (Fixed Version)
 ******************************************************************************/
var quizSchedule = {
  // Initialize quiz schedule functionality
  init: function() {
    if ($('.quiz-schedule-compact').length > 0) {

      // Check if Stimulus controller is already handling the quiz preparation
      // This prevents conflicts between jQuery countdown and Stimulus polling
      if ($('[data-controller="live-quiz"]').length > 0 &&
          $('[data-live-quiz-quiz-preparing-value="true"]').length > 0) {
        console.log('Quiz preparation is being handled by Stimulus controller');
        return; // Exit early to prevent dual refresh mechanisms
      }

      // Clear any existing intervals
      if (this.intervalId) {
        clearInterval(this.intervalId);
      }
      this.fastInterval = false;
      this.reloadScheduled = false; // Flag to prevent multiple reloads

      // Check if we're in the preparation phase
      // The countdown shows time until the worker starts (T-5:00)
      // We want to reload shortly after the worker has started and set the quiz status
      var countdownEl = $('#quiz-countdown');
      if (countdownEl.length) {
        var targetTime = new Date(countdownEl.data('target-time'));
        var now = new Date();
        var diff = targetTime - now;


        // Check if we already marked this as preparation phase
        var inPreparation = sessionStorage.getItem('quiz_preparation_' + targetTime.getTime());

        // If countdown has expired (worker should have started)
        if (diff <= 0) {
          countdownEl.html('<span class="countdown-expired">Loading quiz...</span>');

          // Only schedule reload if we haven't already done so in this page session
          if (!inPreparation && !this.reloadScheduled) {
            this.reloadScheduled = true; // Prevent multiple reloads
            sessionStorage.setItem('quiz_preparation_' + targetTime.getTime(), 'true');

            // Clear the session storage immediately to prevent re-entry
            var storageKey = 'quiz_preparation_' + targetTime.getTime();

            // Set a more specific flag to indicate reload is in progress
            sessionStorage.setItem('quiz_reload_scheduled', 'true');

            // Schedule reload after a short delay
            setTimeout(function() {
              // Clean up ALL quiz-related session storage
              sessionStorage.removeItem(storageKey);
              sessionStorage.removeItem('quiz_reload_scheduled');

              // Clear any abandoned preparation flags from previous attempts
              for (var key in sessionStorage) {
                if (key.startsWith('quiz_preparation_')) {
                  sessionStorage.removeItem(key);
                }
              }

              // Reload the page
              window.location.reload();
            }, 3000); // 3-second delay to ensure worker has time to update status
          }
          return; // Skip normal initialization
        }

        // If we're within 20 seconds of worker start, show preparing message
        if (diff > 0 && diff <= 20000) {
          countdownEl.html('<span class="countdown-expired">Preparing quiz...</span>');
          // Don't reload yet - wait for countdown to reach 0
        }
      }

      this.updateCountdown();
      // Update more frequently as quiz approaches
      this.startCountdownInterval();
      this.showLocalTimes();
      this.showNextQuizLocalTime();
    }
  },

  // Start countdown interval with dynamic frequency
  startCountdownInterval: function() {
    var self = this;
    self.intervalId = setInterval(function() {
      self.updateCountdown();

      // Check if we need to switch to more frequent updates
      var countdownEl = $('#quiz-countdown');
      if (countdownEl.length) {
        var targetTime = new Date(countdownEl.data('target-time'));
        var now = new Date();
        var diff = targetTime - now;

        // If less than 60 seconds remaining and not already updating every second
        if (diff > 0 && diff <= 60000 && !self.fastInterval) {
          clearInterval(self.intervalId);
          self.fastInterval = true;
          // Start updating every second
          self.intervalId = setInterval(function() {
            self.updateCountdown();
          }, 1000);
        }
      }
    }, 5000); // Update every 5 seconds initially
  },

  // Update countdown timer
  updateCountdown: function() {
    var countdownEl = $('#quiz-countdown');
    if (!countdownEl.length) {
      return;
    }

    var targetTime = new Date(countdownEl.data('target-time'));
    var now = new Date();
    var diff = targetTime - now;

    // Show preparing message when within 20 seconds of worker start
    if (diff > 0 && diff <= 20000) {
      countdownEl.html('<span class="countdown-expired">Preparing quiz...</span>');
      // Continue countdown - don't reload yet
    }

    // Auto-refresh shortly after worker starts (when countdown reaches 0)
    if (diff <= 0 && !this.reloadScheduled) {
      // Check if ANY reload is already scheduled
      var reloadScheduled = sessionStorage.getItem('quiz_reload_scheduled');
      if (reloadScheduled === 'true') {
        countdownEl.html('<span class="countdown-expired">Loading quiz...</span>');
        return; // Another reload is already in progress
      }

      // Check if we're already in preparation phase from a previous reload
      // Don't schedule multiple reloads from the same countdown
      var inPreparation = sessionStorage.getItem('quiz_preparation_' + targetTime.getTime());
      if (inPreparation === 'true' || this.reloadScheduled) {
        countdownEl.html('<span class="countdown-expired">Loading quiz...</span>');
        return; // Already scheduled a reload
      }

      this.reloadScheduled = true; // Prevent multiple reloads
      clearInterval(this.intervalId); // Stop the countdown immediately

      countdownEl.html('<span class="countdown-expired">Loading quiz...</span>');

      // Mark that we're entering preparation phase
      sessionStorage.setItem('quiz_preparation_' + targetTime.getTime(), 'true');

      // Set flag to indicate reload is in progress
      sessionStorage.setItem('quiz_reload_scheduled', 'true');

      // Reload after 3 seconds to give worker time to initialize
      setTimeout(function() {
        // Clear all quiz-related session storage before reloading
        sessionStorage.removeItem('quiz_preparation_' + targetTime.getTime());
        sessionStorage.removeItem('quiz_reload_scheduled');

        // Clear any abandoned preparation flags
        for (var key in sessionStorage) {
          if (key.startsWith('quiz_preparation_')) {
            sessionStorage.removeItem(key);
          }
        }

        // Reload the page
        window.location.reload();
      }, 3000);
      return;
    }

    // Don't update countdown if reload is scheduled
    if (this.reloadScheduled) {
      return;
    }

    if (diff <= 0) {
      // Don't just say "Quiz has started" - we need to trigger the reload
      // This will be handled by the code above
      return;
    }

    var days = Math.floor(diff / 86400000);
    var hours = Math.floor((diff % 86400000) / 3600000);
    var minutes = Math.floor((diff % 3600000) / 60000);
    var seconds = Math.floor((diff % 60000) / 1000);

    var parts = [];
    if (days > 0) parts.push(days + 'd');
    if (hours > 0) parts.push(hours + 'h');
    if (minutes > 0) parts.push(minutes + 'm');
    // Always show seconds when less than 1 minute remains
    if (diff < 60000 || (days === 0 && hours === 0 && minutes === 0)) {
      parts.push(seconds + 's');
    }

    countdownEl.html('<i class="fa fa-clock-o"></i> ' + parts.join(' '));
  },

  // Show local times for quiz schedule
  showLocalTimes: function() {
    $('.schedule-local').each(function() {
      var utcTimeStr = $(this).data('utc-time');
      var timeParts = utcTimeStr.split(':');
      var utcHours = parseInt(timeParts[0]);
      var utcMinutes = parseInt(timeParts[1]);

      // Create a date object for today at the specified UTC time
      var now = new Date();
      var utcDate = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), utcHours, utcMinutes, 0));

      // Format in user's local time
      var localTimeStr = utcDate.toLocaleString([], {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true,
        timeZoneName: 'short'
      });

      $(this).text(localTimeStr);
    });
  },

  // Show local time for next quiz
  showNextQuizLocalTime: function() {
    var nextQuizEl = $('.quiz-local-time[data-utc-datetime]');
    var dayEl = $('.quiz-day[data-utc-datetime]');
    if (!nextQuizEl.length) return;

    var utcDatetime = nextQuizEl.data('utc-datetime');
    var utcDate = new Date(utcDatetime);

    // Get day of week in local timezone
    var localDay = utcDate.toLocaleDateString([], {
      weekday: 'long'
    });

    // Format the full date and time in user's local timezone
    var localDateTimeStr = utcDate.toLocaleString([], {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
      timeZoneName: 'short'
    });

    dayEl.text(localDay);
    nextQuizEl.html('<i class="fa fa-clock-o"></i> ' + localDateTimeStr);
  }
};

// DISABLED: quizSchedule initialization - now handled by Stimulus controller
// The live_quiz_controller.js Stimulus controller now handles all quiz timing
// and refresh logic using a single server-driven state machine approach.
// This prevents multiple competing timing systems from conflicting.
/*
// Initialize quiz schedule on document ready
if (typeof $ !== 'undefined' && $.fn && $.fn.ready) {
  $(document).ready(function() {
    quizSchedule.init();
  });
}
*/


