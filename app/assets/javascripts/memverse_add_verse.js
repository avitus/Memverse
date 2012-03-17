/******************************************************************************
 * Remove prior search results anywhere on page
 ******************************************************************************/
function clearSearchResults () {
	resetScrollable();
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
