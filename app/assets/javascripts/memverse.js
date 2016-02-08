// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
// jQuery.noConflict();


// Required for chat channels
// ALV: I think this was required only for Juggernaut

// jQuery.ajaxSetup({
//   'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
// })

// jQuery.fn.submitWithAjax = function() {
//   this.submit(function() {
//     $.post(this.action, $(this).serialize(), null, "script");
//     return false;
//   })
//   return this;
// };

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
function checkAllFields(ref) {
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
          document.manage_verses.action = '/delete_memverses';
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
          document.manage_verses.action = '/delete_memverses';
          return true;
         }
         else
          return false;
        }
        else { // User is deleting between one and all of their verses. Need to alert them if some of these are invisible. This is not necessary in other cases.
        var agree=confirm(I18n.t("js_msgs.some_selected", {quantity: totalChecked}));
         if (agree) {
          document.manage_verses.action = '/delete_memverses';
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

mnemonic = function(text) {
    if(/[\uAC00-\uD7A3]/.test(text)){
        return text.replace(/([\uAC00-\uD7A3])/g, function(s, m){
            return String.fromCharCode(4352 + Math.floor(((m.charCodeAt(0) - 44032) / 588)));}
        );
    }else{
        return text.replace(/([\u00BF-\u1FFF\u2C00-\uD7FF\w])([\u00BF-\u1FFF\u2C00-\uD7FF\w]|[\-'’][\u00BF-\u1FFF\u2C00-\uD7FF\w])*/g,"$1");
    }
};

// Array Remove - By John Resig (MIT Licensed)
Array.remove = function(array, from, to) {
  var rest = array.slice((to || from) + 1 || array.length);
  array.length = from < 0 ? array.length + from : from;
  return array.push.apply(array, rest);
};

// Splits a verse into words
function splitByWords(text){
	// matches optional mixture of hyphens & whitespace: [-—\s]*
	// followed by one or more non-CJK (Chinese/Japanese/Korean) characters: [^\s\u4E00-\u9FFF\u1100-\u11ff\uAC00-\uD7A3]+
	// or one CJK character: [\u4E00-\u9FFF\u1100-\u11ff\uAC00-\uD7A3]
	// followed by optional non-CJK non-word non-whitespace characters (for punctuation): [^\u4E00-\u9FFF\u1100-\u11ff\uAC00-\uD7A3\s]*
	// ending with optional mixture of whitespace and hyphens/dashes only if at the end of text: \s*(?:[-—\s]+$)?
	return text.match(/[-—\s]*(?:[^\u4E00-\u9FFF\u1100-\u11ff\uAC00-\uD7A3\s]+|[\u4E00-\u9FFF\u1100-\u11ff\uAC00-\uD7A3][^\u4E00-\u9FFF\u1100-\u11ff\uAC00-\uD7A3\s]*)\s*(?:[-—\s]+$)?/g) || [];
}

function verseFeedback(correctvs, verseguess, echo, firstletter) {

	firstletter = (typeof firstletter == "undefined") ? false : firstletter;

	var correct;
	var feedback = ""; // find a better way to construct the string

	var guess_words = splitByWords(verseguess);
	guess_words.forEach(function(e, i){
		guess_words[i] = scrub_text(e);
	});
	
	var right_words = splitByWords(correctvs);
	
	var s_right_words = [];
	right_words.forEach(function(e, i){
		 s_right_words[i] = scrub_text(e);
	});

	for (var x in guess_words) {

		if (x < s_right_words.length) { // check that guess isn't longer than correct answer

			var y = parseInt(x) + 1;
			var z = parseInt(x) - 1;
			
			var right_first_letter = /[\uAC00-\uD7A3]/.test(s_right_words[x].charAt(0)) ? String.fromCharCode(4352 + Math.floor((s_right_words[x].charCodeAt(0)) - 44032) / 588) : s_right_words[x].charAt(0);

			// first letter probably in use if this word and the word before it or after it are both single characters
			var fl_prob_in_use = ((guess_words.length >= 2) && (guess_words[x].length == 1 ) && ((guess_words[z] && guess_words[z].length == 1) || (guess_words[y] && guess_words[y].length == 1)));

			if ( /^\s*$/.test(verseguess) ) { // This happens when nothing or only whitespace is in the textarea
				feedback = "Waiting for you to begin typing...";
				correct = false;
			} else if ( guess_words[x] == s_right_words[x] ) {
				// if the word matches exactly
				feedback = feedback + right_words[x];
			} else if (firstletter && fl_prob_in_use && ( guess_words[x] == right_first_letter ) ) {
				// if first letter enabled and first letter sequence and first letter matches
				feedback += right_words[x];
			} else {
				feedback += "... ";
				correct = false;
			}
		}
	}
	
	if ( (guess_words.length == right_words.length) && (correct != false) ) { // determine if correct: should be long enough and not have anything incorrect in it
		correct = true;
		if (!echo) {
			feedback = '< Feedback disabled >';
		}
		feedback += '<div id="matchbox"><span>Correct</span></div>';
	} else { // at this point it must be incorrect; we still need to set correct to false in case user guess has been correct thus far bust still incomplete
		correct = false;
		if (!echo) {	// incorrect and feedback disabled
			feedback = "< Feedback disabled >";
		}
	}

	return {
		feedtext:		feedback,
		correct:		correct
	};

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
	if (ondeck.mnemonic != null && ondeck.mnemonic != "") {
		$('#mtext').text(ondeck.mnemonic);						// Update the mnemonic text
		$('#mnemonic').show();									// Show mnemonic box
		$("#mclose").show();									// Show close box
	}
	else {
		$('#mtext').text('');									// Clear mnemonic text
		$('#mnemonic').hide();									// Hide mnemonic box
	}

	// == Update skip button tooltip
	next_up = ($('#upcoming-verses li.upcoming-verse-ref:visible').length == 0)?"end (no more verses due)":ondeck.skippable;
	$('#next-verse-due').text(next_up);

	return true;

}
