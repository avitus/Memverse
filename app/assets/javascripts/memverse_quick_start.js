$(document).ready(function() {

	var versesAdded = 0;
	var tl;

	$("#minor-tl").click(function() {
		$("#major-translations").hide();
		$("#minor-translations").show();
		$("#foreign-translations").hide();
	});

	$("#global-tl").click(function() {
		$("#major-translations").hide();
		$("#minor-translations").hide();
		$("#foreign-translations").show();
	});

	$(".tl-root").click(function() {
		$("#major-translations").show();
		$("#minor-translations").hide();
		$("#foreign-translations").hide();
	});

	$(".tl-set").click(function() {

		tl = this.id;
		$("#choose-translation").hide();
		$("#choose-time-alloc").show();

		$(".scrollable .pop-verse-group").each(function(e) {
	        if (e != 0)
	            $(this).hide();
	    });
	    
	    $(".next").click(function(){ 
	    	mvScrollNext();
	    });

	    $(".prev").click(function(){
	    	mvScrollPrev();
	    });

		// Load popular verses in chosen translation
		$.getJSON("/popverses/index.json", { tl: tl }, function(pop_verses) {
			$.each (pop_verses, function(i, pv) {
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

		});

	});

	$(".time-set").click(function() {
		$("#choose-time-alloc").hide();
		$("#choose-starting-verses").show();
	});

	// Verse entry and retrieval
	$(".verse-search-by-tl-and-display").observe_field(0.2, function( ) {

		if (ref = parseVerseRef($.trim(this.value))) {
			$.get("/lookup_verse.json", { bk: ref.bk, ch: ref.ch, vs: ref.vs },
				function(data) {
					$("#foundVerse").empty();
					if (typeof(data) !== 'undefined' && data != null) {
						$("#new-verse-entry").hide();
						$("#foundVerse").append($('<h4/>').text(data.ref)).append($('<p/>').text(data.text));
						$("#quick-start-add-verse").html("<a data-remote='true' href='/add/" + data.id + "'class='quick-start-add-button' id='quick-start-add'></a>");
					} else {
						$("#new-verse-entry").slideDown();
						$("#quick-start-add-verse").empty();
						$("#new-verse-entry .quick-start-add-verse").html("<div class='quick-start-add-button'></div>")  // show add button
					};
			}, "json" );
		} else {
			$("#new-verse-entry").hide();		   // Hide new verse entry div
			$("#foundVerse").empty();              // Remove verse
			$("#quick-start-add-verse").empty();   // Remove add button
		}
	});

	// Adding an existing verse
	$('.quick-start-add-section').on("click", ".quick-start-add-button", function() {      // Bind to DIV enclosing button to allow for event delegation

		// Replace button with checkbox
		$(this).fadeOut( 200, function () {
			$(this).replaceWith("<div class='verse-added'></div>");
		});

		// +1 to number of verses
		versesAdded += 1;

		// Check whether user has enough verses to start first memorization session
		if (versesAdded >= 5) {
			$("#start-memorizing").fadeIn();
		};
	});

	// Adding a new verse TODO: this should probably be abstracted into a nice function
	$('.quick-start-new-section').on("click", ".quick-start-add-button", function() {      // Bind to DIV enclosing button to allow for event delegation
		$button   = $('.quick-start-new-section .quick-start-add-button');
		ref       = parseVerseRef( $("#verse").val().trim());
		userVerse = $("#versetext").val();
		newVerse  = cleanseVerseText( userVerse );

		if ( ref ) {
			$.post('/verses.json', { verse: {book: ref.bk, chapter: ref.ch, versenum: ref.vs, translation: tl, text: newVerse, book_index: ref.bi} }, function(data) {
				if (data.msg === "Success") {
					// Show that verse has been added and add verse for user
					$("#versetext").val('');
					$.post("/add/" + data.verse_id, function(data) {
						// Tell user whether verse was saved
						if (data.msg === "Error") {
							alert("We were unable to save the verse to your list of verses.");
						} else {
							// Replace button with checkbox
							$button.fadeOut( 200, function () {
								$(this).replaceWith("<div class='verse-added'></div>");
							});

							// +1 to number of verses
							versesAdded += 1;

							// Check whether user has enough verses to start first memorization session
							if (versesAdded >= 5) {
								$("#start-memorizing").fadeIn();
							};
						};
					});
				} else {
					// Alert user to error
					alert("Verse was not saved successfully. Sorry.");
				}
			}, 'json');
		} else {
			alert("Verse reference doesn't seem to be valid");
		};
	});

	$('#foundVerse').delegate('td.no-dbl-click a', 'click', function() {
		$("#foundVerse").attr('disabled', 'disabled').hide();
	});

}); // End of jQuery document ready