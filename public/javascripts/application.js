// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function stageverse(skip, mv_current) {
	
	var mv = {};
	
	$.getJSON("/memverses/test_next_verse", { skip: skip, mv: mv_current },
		function(data){
				
			mv.finished	= data.finished;
						
			if (!mv.finished)
			{					
				// data for the next verse ...
				mv.ref 			= data.ref;
				mv.id			= data.mv_id;	 
				mv.txt 			= data.next.verse.text;
				mv.versenum		= data.next.verse.versenum;
				mv.skippable	= data.mv_skippable;
				
				// ... and its prior verse
				if(typeof(data.next_prior) !== 'undefined' && data.next_prior != null)
				{
					mv.priortxt	= data.next_prior.verse.text;
					mv.priornum	= data.next_prior.verse.versenum;				 	
				}
				else
				{
					mv.priortxt	= null;
					mv.priornum	= null;
				}
			}
			
			if (skip) { // we need to get this verse loaded asap
				insertondeck(mv)
			} 
								
	}); // end of getJSON
	
	return mv;	// putting this in callback function results in null being returned
};


function insertondeck(ondeck) {
	
	$(".verse-ref").text(ondeck.ref);							// Update references on testing box					
	$("#verseguess").val('');									// Clear the input box 
	$("#verseguess").focus();									// Put cursor in input box
	$("#ajaxWrapper").text('');									// Clear the feedback 
	$('.quickFlip').quickFlipper( {}, 0 );						// Reset the flashcard 
	$("#flashcard-back-text #current-text").text(ondeck.txt);	// Update current verse on back of flash card
	$(".current-versenum").text(ondeck.versenum);
	$('#ff-button').toggle(ondeck.skippable);					// Hide/Show fast forward button
						
	// == Update prior verse and reference	
	if (typeof(ondeck.priortxt) !== 'undefined' && ondeck.priortxt != null)	{
		$(".priorVerse").show()				
		$(".prior-text").text(ondeck.priortxt);   		
		$(".prior-versenum").text(ondeck.priornum);				
	}
	else {
		$(".priorVerse").hide()
	}
	
	// == Update front of flash card with Mnemonic (if necessary)	
	return true
	
}



	