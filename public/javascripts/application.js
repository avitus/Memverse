// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Thanks to Dustin for post: http://www.dustindiaz.com/check-one-check-all-javascript/
function checkAllFields(ref)
{
var chkAll = document.getElementById('checkAll');
var checks = document.getElementsByName('mv[]');
var boxLength = checks.length;
var allChecked = false;
var totalChecked = 0;
    if ( ref == 1 )  // Selecting all verses
    {
        if ( chkAll.checked == true )
        {
            for ( i=0; i < boxLength; i++ )
            checks[i].checked = true;
        }
        else
        {
            for ( i=0; i < boxLength; i++ )
            checks[i].checked = false;
        }
    }
    if (ref == 2)  // Selecting specific verses
    {
        for ( i=0; i < boxLength; i++ )
        {
            if ( checks[i].checked == true )
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
    for ( j=0; j < boxLength; j++ )
    {
        if ( checks[j].checked == true )
        totalChecked++;
    }
    if ( ref == 3 ) // Deleting Verses
    {
        if ( totalChecked == 1 ) {
        var agree=confirm("Are you sure you want to delete the selected verse?");
         if (agree) {
          document.manage_verses.action = '/memverses/delete_verses';
          return true;
         }
         else {
          return false;
         }
        }
        else if ( totalChecked == 0 ) {
        alert("You should first select the verses using the check boxes on the left.");
        return false;
        }
        else if ( totalChecked == boxLength ) {
        var agree=confirm("Are you sure you want to delete all "+totalChecked+" of your verses?");
         if (agree) {
          document.manage_verses.action = '/memverses/delete_verses';
          return true;
         }
         else
          return false;
        }
        else {
        var agree=confirm("Are you sure you want to delete the "+totalChecked+" selected verses?");
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
        if ( totalChecked == 0 ) {
        alert("You should first select the verses using the check boxes on the left.");
        return false;
        }
        else {
        return true;
        }
    }
}


function update_upcoming(num_verses, mv_id) {
	$.ajax( {
		url:		'/upcoming_verses',
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
		success:	function(data) {}
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
		} // end of success function
		
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
	
	$(".verse-ref").text(ondeck.ref);							// Update references on testing box					
	$(".verse-tl").text(' [' + ondeck.tl + ']');				// Update translation on testing box					
	$("#verseguess").val('');									// Clear the input box 
	$("#verseguess").focus();									// Put cursor in input box
	$("#ajaxWrapper").text('');									// Clear the feedback 
	$('.quickFlip').quickFlipper( {}, 0 );						// Reset the flashcard 
	$("#flashcard-back-text #current-text").text(ondeck.text);	// Update current verse on back of flash card
	$(".current-versenum").text(ondeck.versenum);				// Update verse number superscript
	$('#ff-button').toggle(ondeck.skippable);					// Hide/Show fast forward button
	$('.mnemonic').text('');									// Clear the mnemonic
	$('.mnemonic').text(ondeck.mnemonic);						// Update front of flash card with Mnemonic (if necessary)

	// == Update prior verse and reference	
	if (typeof(ondeck_prior) !== 'undefined' && ondeck_prior != null) {
		$(".priorVerse").show();
		$(".prior-text").text(ondeck_prior.text);
		$(".prior-versenum").text(ondeck_prior.versenum);
	}
	else {
		$(".priorVerse").hide();
	}
	
	return true;
	
}
