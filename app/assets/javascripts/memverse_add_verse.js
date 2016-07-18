/******************************************************************************
 * Flexible verse searching
 ******************************************************************************/
function flexversesearch(text){

    // Truncate queries of excessive length
    // var text = jQuery.trim(user_text).substring(0, 100).split(" ").slice(0, -1).join(" ");

	// User is looking for a single verse						
	if (ref = parseVerseRef($.trim(text))) {
		$.get("/lookup_verse.json", { bk: ref.bk, ch: ref.ch, vs: ref.vs, tl: tl },
			function(verse) {	

				// Clear search results
				clearSearchResults();
				$(".verse-search-results-scroll #actions a").hide();
				$(".verse-search-results-scroll div.scrollable").hide();
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
	} else if (ref = parsePassageRef($.trim(text))) {
		$.get("/lookup_passage.json", { bk: ref.bk, ch: ref.ch, vs_start: ref.vs_start, vs_end: ref.vs_end, tl: tl },
			function(verses) {
				
				// TODO: Potentially insert missing verses with option to create a new verse
				// TODO: Don't clear search results if search is for the same ref
				clearSearchResults();         // clear existing search results
				displaySearchResults(verses); // display new search results
				if (validChapterRef($.trim(text))) {
					checkChapter(ref, tl);
				}
		}, "json" );
	
	// User didn't enter a verse reference ... do a keyword search
	} else {
		$.get("/search_verse.json", { searchParams: $.trim(text + " " + tl)  },
			function(verses) {
			
				clearSearchResults();         // clear existing search results
				displaySearchResults(verses); // display new search results			
			
		}, "json" );
	}
} // end flexversesearch function

/******************************************************************************
 * Remove prior search results anywhere on page
 ******************************************************************************/
function clearSearchResults () {
	$('.scrollable .items').empty();
	$("#foundVerse").empty();
	$("#add-verse-button").empty();
	$("#versetext").val('');
	$(".verse-added").replaceWith("<a id='add-chapter' class='add-chapter-button' href='#' style='display: inline;'>Add Chapter</a>");
	$("#add-chapter").fadeOut("fast");
};

/******************************************************************************
 * Display scrollable list of results
 ******************************************************************************/
function displaySearchResults (verses) {
	$(".verse-search-results-scroll #actions a, .verse-search-results-scroll div.scrollable, .verse-search-results-scroll").show();
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
		} else if ((data.errors) && (!data.errors.length < 1)) {
			alert(data.errors.join()); // New verse could not be created and errors returned; display errors
		} else {
			alert("Something went wrong. The verse was not saved.");  // New verse could not be created and no errors returned
		}
	}, 'json');	
};


/******************************************************************************
 * Check for chapter availability
 ******************************************************************************/
function checkChapter(ref, tl) {
	$.get("/chapter_available.json", {bk: ref.bk, ch: ref.ch, tl: tl}, function(response) {
		if (response === true) {
			$("#add-chapter").fadeIn("fast");
		}
	});
};
