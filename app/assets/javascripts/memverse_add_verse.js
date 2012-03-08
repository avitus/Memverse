function resetScrollable() {

	// get handle to scrollable API
	var api = $(".scrollable").data("scrollable");
	
	// use API to move back to the beginning
	api.begin();
}


function clearSearchResults () {
	resetScrollable();
	$('.scrollable .items').empty();
	$("#foundVerse").empty();
	$("#quick-start-add-verse").empty();
		
};

function displaySearchResults (verses) {
	$.each (verses, function(i, pv) {
		// We need to group popular verses		
		if (i % 3 == 0) {
			// Start new group
			var $new_vs_group = $('<div/>').addClass('pop-verse-group');
			$('.items').append($new_vs_group);
		} 
		var $new_pv = $('<div/>').addClass('item quick-start-show-verse')
			.append($('<h4/>').text(pv.ref))
			.append($('<p/>').text(pv.text))
			.append('<div class="quick-start-add-verse"><a data-remote="true" href="/add/' + pv.id + '" class="quick-start-add-button" id="quick-start-add"></a></div>');
		$('.pop-verse-group').filter(':last').append($new_pv);																
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
		
					if (typeof(verse) !== 'undefined' && verse != null) {
						$("#new-verse-entry").hide();												
						$("#foundVerse").append($('<h4/>').text(verse.ref)).append($('<p/>').text(verse.text));
						$("#quick-start-add-verse").html("<a data-remote='true' href='/add/" + verse.id + "'class='quick-start-add-button' id='quick-start-add'></a>");
					} else {					
						$("#new-verse-entry").slideDown();																
						$("#quick-start-add-verse").empty();
						$("#new-verse-entry .quick-start-add-verse").html("<div class='quick-start-add-button'></div>")  // show add button
					};

			}, "json" );	
					
		// User is searching for a passage
		} else if (ref = parsePassageRef($.trim(this.value))) {
			$.get("/lookup_passage.json", { bk: ref.bk, ch: ref.ch, vs_start: ref.vs_start, vs_end: ref.vs_end },
				function(verses) {
					
					// TODO: Insert missing verses with option to create a new verse
					
					clearSearchResults();  // clear existing search results
					displaySearchResults(verses); // display new search results
					
			}, "json" );
		
		// User didn't enter a verse reference ... do a keyword search
		} else {
			$.get("/search_verse.json", { searchParams: $.trim(this.value)  },
				function(verses) {
					
					clearSearchResults();  // clear existing search results
					displaySearchResults(verses); // display new search results			
					
			}, "json" );
		}			
	});
	
});