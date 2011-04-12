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

$(document).ready(function() {
  $("#chat_window").submitWithAjax();
})



// Verse filtering; used script from http://net.tutsplus.com/tutorials/javascript-ajax/using-jquery-to-manipulate-and-filter-data/

$(document).ready(function() {
		
	//default each row to visible
	$('tbody tr').addClass('visible');
	
	//overrides CSS display:none property
	//so only users w/ JS will see the
	//filter box
	$('#searchico').show();
	$('#vsfilter').hide();
	$('#searchico').click(function() {
	$('#vsfilter').slideToggle(400);
        return false;
        });
// Thanks to Sam Dunn: http://buildinternet.com/2009/01/changing-form-input-styles-on-focus-with-jquery/
     $('input[name="filter"]').addClass("idleField");  
     $('input[name="filter"]').focus(function() {  
         $(this).removeClass("idleField").addClass("focusField");  
         if (this.value == this.defaultValue){  
             this.value = '';  
         }  
         if(this.value != this.defaultValue){  
             this.select();  
         }  
     });  
     $('input[name="filter"]').blur(function() {  
         $(this).removeClass("focusField").addClass("idleField");  
         if ($.trim(this.value) == ''){
           this.value = (this.defaultValue ? this.defaultValue : '');
         }
     });  
	
	$('#filter').keyup(function(event) {
		//if esc is pressed or nothing is entered
    if (event.keyCode == 27 || $(this).val() == '') {
			//if esc is pressed we want to clear the value of search box
			$(this).val('');
			
			//we want each row to be visible because if nothing
			//is entered then all rows are matched.
      $('tbody tr').removeClass('visible').show().addClass('visible');
    }

		//if there is text, lets filter
		else {
      filter('tbody tr', $(this).val());
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

// Thanks to Dustin for post: http://www.dustindiaz.com/check-one-check-all-javascript/
function checkAllFields(ref)
{
var chkAll = document.getElementById('checkAll');
// var checks = document.getElementsByName('mv[]');
var visiblechecks = $('input[name="mv[]"]:visible');
var invisiblechecked = $('input[name="mv[]"]').not(':visible');
// var boxLength = checks.length;
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
	$("#complete-hint").hide();									// Hide the hint
	$("#currentVerse").show();									// Show the feedback block
	$(".toggle-hint").text("Show Hint");						// Reset show-hide hint toggle
	$(".current-text").text(ondeck.text);						// Update current verse on back of flash card
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
