$(document).ready(function() {

	// Verse entry and retrieval
	$(".flex-verse-search").observe_field(0.2, function( ) { 
								
		if (ref = parseVerseRef($.trim(this.value))) {
			$.get("/lookup_verse.json", { bk: ref.bk, ch: ref.ch, vs: ref.vs },
				function(data) {	

			}, "json" );			
		} else if (ref = parsePassageRef($.trim(this.value))) {
			$.get("/lookup_passage.json", { bk: ref.bk, ch: ref.ch, vs_start: ref.vs_start, vs_end: ref.vs_end },
				function(data) {
					
			}, "json" );
		} else {
			// User didn't enter a verse reference ... do a keyword search
			$.get("/search_verse.json", { searchParams: $.trim(this.value)  },
				function(data) {
					
			}, "json" );
		}			
	});
	
});