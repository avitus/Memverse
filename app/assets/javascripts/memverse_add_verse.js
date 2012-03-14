/******************************************************************************
 * Remove prior search results anywhere on page
 ******************************************************************************/
function clearSearchResults () {
	resetScrollable();
	$('.scrollable .items').empty();
	$("#foundVerse").empty();
	$("#add-verse-button").empty();
	$("#versetext").val('');
	$("#add-chapter").hide();
};

/******************************************************************************
 * Display scrollable list of results
 ******************************************************************************/
function displaySearchResults (verses) {
	$(".verse-search-results-scroll").show();
	$("#verse-search-single-result").hide();
	$.each (verses, function(i, pv) {
		// We need to group popular verses		
		if (i % 3 == 0) {
			// Start new group
			var $new_vs_group = $('<div/>').addClass('pop-verse-group');
			$('.items').append($new_vs_group);
		} 
		var $new_pv = $('<div/>').addClass('item quick-start-show-verse')
			.append($('<div class="verse-and-ref" />')
				.append($('<h4/>').text(pv.ref))
				.append($('<p/>').text(pv.text)) )
			.append('<div class="add-verse-button"><a data-remote="true" href="/add/' + pv.id + '" class="quick-start-add-button" id="quick-start-add"></a></div>');
		$('.pop-verse-group').filter(':last').append($new_pv);																
	});	
};

/******************************************************************************
 * Create new verse in database and add for user
 ******************************************************************************/
function createVerseAndAdd (ref, tl, txt, $button) {
	$.post('/verses.json', { verse: {book: ref.bk, chapter: ref.ch, versenum: ref.vs, translation: tl, text: txt, book_index: ref.bi} }, function(data) {
		if (data.msg === "Success") {
			$.post("/add/" + data.verse_id, function(data) {
				if (data.msg === "Error") {
					alert("The verse was created but could not be saved to your list.");  // Couldn't save verse for user 
				} else {
					$button.fadeOut( 200, function () {
						$(this).replaceWith("<div class='verse-added'></div>");
					});	
				};
			});
		} else {
			alert("Something went wrong. The verse was not saved.");  // New verse could not be created
		}
	}, 'json');	
};


/******************************************************************************
 * Check for chapter availability
 ******************************************************************************/
function checkChapter(ref) {
	$.get("/chapter_available.json", {bk: ref.bk, ch: ref.ch}, function(response) {
		if (response === true) {
			$("#add-chapter").fadeIn("fast");			
		}
	});
};



$(document).ready(function() {

	// initialize scrollable module
	$(".scrollable").scrollable({ vertical: true, mousewheel: true });	

	// Verse entry and retrieval
	$(".flex-verse-search").observe_field(0.2, function( ) { 
				
		// User is looking for a single verse						
		if (ref = parseVerseRef($.trim(this.value))) {
			$.get("/lookup_verse.json", { bk: ref.bk, ch: ref.ch, vs: ref.vs },
				function(verse) {	

					// Clear search results
					clearSearchResults();
					$(".verse-search-results-scroll").hide();
					$("#verse-search-single-result").show();
							
					if (typeof(verse) !== 'undefined' && verse != null) {
						$("#new-verse-entry").hide();												
						$("#foundVerse").append($('<h4/>').text(verse.ref)).append($('<p/>').text(verse.text));
						$("#add-verse-button").html("<a data-remote='true' href='/add/" + verse.id + "'class='quick-start-add-button' id='quick-start-add'></a>");
					} else {					
						$("#new-verse-entry").slideDown();																
						$("#add-verse-button").empty();
						$("#new-verse-entry .add-verse-button").html("<div class='quick-start-add-button'></div>")  // show add button
					};

			}, "json" );	
					
		// User is searching for a passage
		} else if (ref = parsePassageRef($.trim(this.value))) {
			$.get("/lookup_passage.json", { bk: ref.bk, ch: ref.ch, vs_start: ref.vs_start, vs_end: ref.vs_end },
				function(verses) {
					
					// TODO: Insert missing verses with option to create a new verse
					
					clearSearchResults();         // clear existing search results
					displaySearchResults(verses); // display new search results
					checkChapter(ref);
					
			}, "json" );
		
		// User didn't enter a verse reference ... do a keyword search
		} else {
			$.get("/search_verse.json", { searchParams: $.trim(this.value)  },
				function(verses) {
					
					clearSearchResults();         // clear existing search results
					displaySearchResults(verses); // display new search results			
					
			}, "json" );
		}			
	});
	
	// User adds a new verse
	$('.create-and-add').on("click", ".quick-start-add-button", function() {      // Bind to DIV enclosing button to allow for event delegation
		$button   = $('.create-and-add .quick-start-add-button');
		ref       = parseVerseRef( $("#verse").val().trim());
		newVerse  = cleanseVerseText( $("#versetext").val() );		
		tl        = "NIV";
					
		if ( ref ) { 
			createVerseAndAdd(ref, tl, newVerse, $button);
		} else {
			alert("The Bible reference you have entered is not valid.")
		};	
	});	

	// User adds entire passage	
	$('.add-chapter').on("click", ".add-chapter-button", function() {		
		ref = parsePassageRef( $("#verse").val().trim() );
		$.post("/add_chapter.json", { bk: ref.bk, ch: ref.ch }, function(response) { /* Alert user */ });
	});
	
});