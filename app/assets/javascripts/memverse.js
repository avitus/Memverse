// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
// jQuery.noConflict();


// Required for chat channels
jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
})

jQuery.fn.submitWithAjax = function() {
  this.submit(function() {
    $.post(this.action, $(this).serialize(), null, "script");
    return false;
  })
  return this;
};

// Verse filtering; used and tweaked script from http://net.tutsplus.com/tutorials/javascript-ajax/using-jquery-to-manipulate-and-filter-data/
function filtersetup(){
	var delay = (function(){
	  var timer = 0;
	  return function(callback, ms){
	    clearTimeout (timer);
	    timer = setTimeout(callback, ms);
	  };
	})(); // source: http://stackoverflow.com/questions/1909441/jquery-keyup-delay
	var $searchval = ""; 
	$(document).ready(function() {
			
		//default each row to visible
		$('tbody tr').addClass('visible');
		
		var $searchico = $('#searchico');
		var $filter = $('#filter');
		
		//overrides CSS display:none property
		//so only users w/ JS will see the search icon
		$searchico.show();
		$searchico.click(function() {
			$('#vsfilter').slideToggle(400);
			$filter.focus();
			return false;
		});
	// Thanks to Sam Dunn: http://buildinternet.com/2009/01/changing-form-input-styles-on-focus-with-jquery/
	     $filter.focus(function() {  
	         $(this).removeClass("idleField").addClass("focusField");  
	         if (this.value == this.defaultValue){  
	             this.value = '';  
	         }  
	         if(this.value != this.defaultValue){  
	             this.select();  
	         }  
	     });  
	     $filter.blur(function() {  
	         $(this).removeClass("focusField").addClass("idleField");  
	         if ($.trim(this.value) == ''){
	           this.value = (this.defaultValue ? this.defaultValue : '');
	         }
	     });  
		
		$filter.keyup(function(event) {
		//if esc is pressed
	    if (event.keyCode == 27) {
			//if esc is pressed we want to clear the value of search box and hide it again
			$filter.val('');
			$('#vsfilter').slideToggle(400);
		}
		//if nothing is entered
		if ($(this).val() == '') {
			//we want each row to be visible because if nothing
			//is entered then all rows are matched.
			$('tbody tr').removeClass('visible').show().addClass('visible');
	    }
		//else: there is text, let's set delay to filter (if user updates query soon, we won't be wasting resources filtering old)
		else {
			$searchval = $(this).val();
			delay(function(){
				filter('tbody tr', $searchval);
			}, 300 );
	    }
	
		});
	});
	
	
	//filter results based on query
	function filter(selector, query) {
	//	query	=	$.trim(query); //trim white space
	//  query = query.replace(/ /gi, '|'); //add OR for regex
	
	  $(selector).each(function() {
	    ($(this).text().search(new RegExp(query, "i")) < 0) ? $(this).hide().removeClass('visible') : $(this).show().addClass('visible');
	  });
	}
}
// Thanks to Dustin for post: http://www.dustindiaz.com/check-one-check-all-javascript/
function checkAllFields(ref)
{
var chkAll = document.getElementById('checkAll');
var visiblechecks = $('input[name="mv[]"]:visible');
var invisiblechecked = $('input[name="mv[]"]').not(':visible');
var visibleboxLength = visiblechecks.length;
var invisibleboxLength = invisiblechecked.length;
var allChecked = false;
var totalChecked = 0; // Number of visible checkboxes checked.
    if ( ref == 1 )  // Selecting all visible verses
    {
        if ( chkAll.checked == true )
        {
            for ( i=0; i < visibleboxLength; i++ )
            visiblechecks[i].checked = true;
        }
        else
        {
            for ( i=0; i < visibleboxLength; i++ )
            visiblechecks[i].checked = false;
        }
    }
    if (ref == 2)  // Selecting specific verses
    {
        for ( i=0; i < visibleboxLength; i++ )
        {
            if ( visiblechecks[i].checked == true )
            {
            allChecked = true;
            continue;
            }
            else
            {
            allChecked = false;
            break;
            }
        }
        if ( allChecked == true )
        chkAll.checked = true;
        else
        chkAll.checked = false;
    }
    for ( j=0; j < visibleboxLength; j++ )
    {
        if ( visiblechecks[j].checked == true )
        totalChecked++;
    }
    if ( ref == 3 ) // Deleting Verses
    {
        for ( k=0; k < invisibleboxLength; k++ )
        invisiblechecked[k].checked = false; // This unchecks invisible boxes before any deletion (or even deletion cancelation) occurs.
        if ( totalChecked == 1 ) {
        var agree=confirm(I18n.t("js_msgs.delete_one"));
         if (agree) {
          document.manage_verses.action = '/memverses/delete_verses';
          return true;
         }
         else {
          return false;
         }
        }
        else if ( totalChecked == 0 ) {
        alert(I18n.t("js_msgs.none_selected"));
        return false;
        }
        else if ( totalChecked == visibleboxLength ) {
        var agree=confirm(I18n.t("js_msgs.all_selected", {quantity: totalChecked}));
         if (agree) {
          document.manage_verses.action = '/memverses/delete_verses';
          return true;
         }
         else
          return false;
        }
        else { // User is deleting between one and all of their verses. Need to alert them if some of these are invisible. This is not necessary in other cases.
        var agree=confirm(I18n.t("js_msgs.some_selected", {quantity: totalChecked}));
         if (agree) {
          document.manage_verses.action = '/memverses/delete_verses';
          return true;
         }
         else
          return false;
        }
    }
    if ( ref == 4 ) // Showing Verses
    {
        for ( k=0; k < invisibleboxLength; k++ )
        invisiblechecked[k].checked = false; // This unchecks invisible boxes.
        if ( totalChecked == 0 ) {
        alert(I18n.t("js_msgs.none_selected"));
        return false;
        }
        else {
        return true;
        }
    }
	if ( ref == 5 ) // Showing Prompts
    {
        for ( k=0; k < invisibleboxLength; k++ )
        invisiblechecked[k].checked = false; // This unchecks invisible boxes.
        if ( totalChecked == 0 ) {
        	alert(I18n.t("js_msgs.none_selected"));
        	return false;
        }
        else {
			document.manage_verses.action = '/memverses/show_prompt';
        	return true;
        }
    }
}

// Array Remove - By John Resig (MIT Licensed)
		Array.remove = function(array, from, to) {
		  var rest = array.slice((to || from) + 1 || array.length);
		  array.length = from < 0 ? array.length + from : from;
		  return array.push.apply(array, rest);
		};

function versefeedback(correctvs, verseguess, echo) {
	guesstext   = $.trim(verseguess.replace(/\s+/g, " ")); // Remove double spaces from guess and trim
	correcttext = $.trim(unescape(correctvs.replace(/\s+/g, " "))); // Remove any double spaces - shouldn't be any
	
	var correct = false;
	var feedback = ""; // find a better way to construct the string

	guess_words = guesstext.split(/\s-\s|\s-|\s/);
	right_words = correcttext.split(/\s-\s|\s-|\s/);

	if (echo) {
					
		for (x in guess_words) {
			if (x < right_words.length) { // check that guess isn't longer than correct answer
				if ( guess_words[x].toLowerCase().replace(/[^0-9a-z]+/g, "") == right_words[x].toLowerCase().replace(/[^0-9a-z]+/g, "") ) {
					feedback = feedback + right_words[x] + " ";
				}
				else if ( guesstext == "" ) { // This happens when nothing is in the textarea
					feedback = "Waiting for you to begin typing..."
				}
				else if ( guess_words[x] == "") {
					// Most likely scenario: the last character was a dash ("-") that was used to split, and now this is empty. We don't want to add "... " to feedback.
					// Only happens to dashes at the end of the text. Other ones are already handled.
					feedback = feedback;
				}
				else {
					feedback = feedback + "... ";
				}
					y = parseInt(x) + 1;
				if (right_words[y] == "-" || right_words[y] == "—" ) {
					feedback = feedback + right_words[y] + " ";
					// Remove the dash from the array
					Array.remove(right_words, y);
				}
			}
		}
	}
	else {
		feedback = "< Feedback disabled >";
	}
	
	// Check for exact match
	match = ( $.trim( verseguess.toLowerCase().replace(/[^a-z ]|\s-|\s—/g, '').replace(/\s+/g, " ") ) == $.trim( unescape(correctvs).toLowerCase().replace(/[^a-z ]|\s-|\s—/g, '').replace(/\s+/g, " ") ) );
	if (match) {
		feedback = feedback + '<div id="matchbox"><p>Correct</p></div>';
		correct = true;
	}
	
	return {
		feedtext:		feedback,
		correct:		correct
	};
	
}

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

function getScore(questionAnswer, userAnswer, questionType) {
	
	switch(questionType) {
		case 'recitation':
	    	return scoreRecitation(questionAnswer, userAnswer)
	    break;
		
		case 'reference':
	    	return scoreReference(questionAnswer, userAnswer)        	
		break;
		
		default:
	    	return 0
	    	
	}	
	
}

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

	score = 12 - (calculate_levenshtein_distance(right_words, user_words));

	if (score < 0) {score = 0;} // Prevents score from being less than 0.

	if (score == 12) {
		msg = "You answered perfectly and scored 12 points! Good job.";
	}
	else if (score >= 1) {
		msg = "Although that wasn't perfect, you still received " + score + " points. Keep trying!";
	}
	else {
		msg = "I'm sorry, but that was not correct.";
	}

	return { score: score, msg: msg };
}

function scoreReference(verseref, userref) {
	
	var score, msg;
	
	user    = $.trim(userref.toLowerCase().replace(/\s+/g, " "));
	correct = $.trim(verseref.toLowerCase().replace(/\s+/g, " "));

	user_book  = user.substring(0,parseInt(user.lastIndexOf(' '))+1);
	right_book = correct.substring(0,parseInt(correct.lastIndexOf(' '))+1);

	user_chapter = user.substring(parseInt(user.lastIndexOf(' '))+1,user.indexOf(':'));
	right_chapter = correct.substring(parseInt(correct.lastIndexOf(' '))+1,correct.indexOf(':'));

	user_verse  = user.substring(parseInt(user.indexOf(':'))+1);
	right_verse = correct.substring(parseInt(correct.indexOf(':'))+1);

	if ( user_book == "" || user_chapter == "" || user_verse == "" || user.indexOf(':') == "-1") {
		alert("Please format your reference answer as Book Chapter:Verse (for example, Genesis 1:1-2) and try again.\n\nIf you are unsure of part of the reference, just take your best guess. Thank you!");
		return false;
	}

	score = 0;

	if (user_book == right_book) {score = score + 4;}
	if (user_chapter == right_chapter) {score = score + 4;}
	if (user_verse == right_verse) {score = score + 4;}

	if (score == 12) {
		msg = "You answered perfectly and scored 12 points! Good job.";
	} else if (score >= 1) {
		msg = "Although that wasn't perfect, you still received " + score + " points. Keep trying! The correct reference was " + verseref + " (you entered " + userref + ").";
	} else {
		msg = "Sorry, but that was not correct. The correct reference was " + verseref + ".";
	}

	return { score: score, msg: msg };
}

function update_upcoming(num_verses, mv_id) {
	$.ajax( {
		url:		'/upcoming_verses.html',
		dataType:	'html',
		async:		true,
		data:		{ mv_id: mv_id },
		success:	function(data) {
			// Insert the refreshed data
			$("#upcoming-verses").html(data);
		} // end of success function
		
	});	
}

function log_progress(user_id) {
	$.ajax( {
		url:		'/save_progress_report',
		dataType:	'json',
		async:		false,
		data:		{ user_id: user_id },
		success:	function(data) {},
		error: 		function(xhr, status, e) { alert('Sorry, we could not save your progress: ' + status); }			
	});
}

function stageverses(mv_current) {
	
	var finished;
	var mv				= {};
	var mv_skip			= {};
	var mv_prior		= {};
	var mv_prior_skip	= {};	
	
	$.ajax( {
		url:		'/test_next_verse',
		dataType:	'json',
		async:		false,
		data:		{ mv: mv_current },
		success:	function(data) {
		
			finished = data.finished;
			
			if (!finished) {
				mv				= data.mv;
				mv_skip			= data.mv_skip;
				mv_prior		= data.prior_mv;
				mv_prior_skip	= data.prior_mv_skip;
			}
		}, // end of success function
		
		error: function(xhr, status, e) {
			alert('Unable to load next verse: ' + status);
		}	
	});
	
	return {
		finished:		finished,
		mv:				mv,
		mv_skip:		mv_skip,
		mv_prior:		mv_prior,
		mv_prior_skip:	mv_prior_skip	
	};
}

function insertondeck(ondeck, ondeck_prior) {
	
	$(".verse-ref").text(ondeck.ref);							                    // Update references on testing box					
	$(".verse-tl").text(' [' + ondeck.tl + ']');				                    // Update translation on testing box					
	$("#verseguess").val('').focus();							                    // Clear then place cursor in the input box
	$("#ajaxWrapper").text('');									                    // Clear the feedback 
	$("#complete-hint").hide();									                    // Hide the hint
	$("#currentVerse").show();									                    // Show the feedback block
	$(".toggle-hint").text(I18n.t("memverses.test_verse_quick.show_verse")).show();	// Reset show-hide verse toggle and show it
	$(".current-text").text(ondeck.text);						                    // Update current verse on back of flash card
	$(".current-versenum").text(ondeck.versenum);				                    // Update verse number superscript
	$('#ff-button').toggle(ondeck.skippable);					                    // Hide/Show fast forward button
	$('#waiting').show();										                    // Show the "Waiting for you to begin" span

	// == Update prior verse and reference	
	if (typeof(ondeck_prior) !== 'undefined' && ondeck_prior != null) {
		$(".priorVerse").show();
		$(".prior-text").text(ondeck_prior.text);
		$(".prior-versenum").text(ondeck_prior.versenum);
	}
	else {
		$(".priorVerse").hide();
	}
	
	// == Update mnemonic
	if (ondeck.mnemonic != null) {
		$('#mtext').text(ondeck.mnemonic);						// Update the mnemonic text
		$('#mnemonic').show();									// Show mnemonic box
		$("#mclose").show();									// Show close box
	}
	else {
		$('#mtext').text('');									// Clear mnemonic text
		$('#mnemonic').hide();									// Hide mnemonic box
	}
	
	return true;
	
}
