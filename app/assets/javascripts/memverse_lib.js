BIBLEBOOKS = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
	          '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
	           'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel',
	           'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
	           'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
	           'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
	           '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']

BIBLEABBREV = ['Gen', 'Ex', 'Lev', 'Num', 'Deut', 'Josh', 'Judg', 'Ruth', '1 Sam', '2 Sam',
              '1 Kings', '2 Kings','1 Chron', '2 Chron', 'Ezra', 'Neh', 'Es', 'Job', 'Ps', 'Prov',
              'Eccl', 'Song', 'Isa', 'Jer', 'Lam', 'Ezk', 'Dan', 'Hos', 'Joel',
              'Amos', 'Obad', 'Jonah', 'Mic', 'Nahum', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal', 'Matt',
              'Mark', 'Luke', 'Jn', 'Acts', 'Rom', '1 Cor', '2 Cor', 'Gal', 'Eph', 'Phil',
              'Col', '1 Thess', '2 Thess', '1 Tim', '2 Tim', 'Tit', 'Phlm', 'Heb', 'James',
              '1 Pet', '2 Pet', '1 John', '2 John', '3 John', 'Jude', 'Rev']

SPANISHBOOKS = ['Génesis', 'Éxodo', 'Levitico', 'Números', 'Deuteronomio', 'Josué', 'Jueces', 'Rut', '1 Samuel', '2 Samuel', '1 Reyes',
                '2 Reyes', '1 Crónicas', '2 Crónicas', 'Esdras', 'Nehemías', 'Ester', 'Job', 'Salmos', 'Proverbios', 'Eclesiastés', 'Cantares',
                'Isaías', 'Jeremías', 'Lamentaciones', 'Ezequiel', 'Daniel', 'Oseas', 'Joel', 'Amós', 'Abdías', 'Jonás', 'Miqueas', 'Nahún', 'Habacuc',
                'Sofonías', 'Hageo', 'Zacarías', 'Malaquías', 'Mateo', 'Marcos', 'Lucas', 'Juan', 'Hechos', 'Romanos', '1 Corintios', '2 Corintios',
                'Gálatas', 'Efesios', 'Filipenses', 'Colosenses', '1 Tesalonicenses', '2 Tesalonicenses', '1 Timoteo', '2 Timoteo', 'Tito', 'Filemón',
                'Hebreos', 'Santiago', '1 Pedro', '2 Pedro', '1 Juan', '2 Juan', '3 Juan', 'Judas','Apocalipsis']

SPANISHABBREV = [ 'Gén', 'Éxod', 'Lev', 'Núm', 'Deut', 'Jos', 'Jue', 'Rut', '1 Sam', '2 Sam', '1 Re', '2 Re', '1 Cró', '2 Cró', 'Esd',
                  'Neh', 'Est', 'Job', 'Sal', 'Prov', 'Ecl', 'Cant', 'Is', 'Jer', 'Lam',
                  'Ez', 'Dan', 'Os', 'Jl', 'Am', 'Abd', 'Jon', 'Miq', 'Nah', 'Hab', 'Sof', 'Ag', 'Zac', 'Mal', 'Mt', 'Mc', 'Lc',
                  'Jn', 'Hech', 'Rom', '1 Cor', '2 Cor', 'Gál', 'Ef', 'Fil', 'Col', '1 Tes', '2 Tes', '1 Tim', '2 Tim', 'Tit', 'Filem',
                  'Heb', 'Sant', '1 Pe', '2 Pe', '1 Jn', '2 Jn', '3 Jn', 'Jds', 'Apoc']

/******************************************************************************
 * Verse Search
 *
 * Note: use this function in preference to 'flexversesearch' as this function
 *       does not co-mingle the displaying of the results. In retrospect there
 *       should be chainable functions so that we can do something like:
 *           .mv_search().display_verses()
 *       but the callback will suffice for now.
 ******************************************************************************/
function mv_search(userText, displayResultsFn) {

    // This function definition is necessary to avoid repetition in the different types of
    // search queries. It handles the custom callback function for mv_search
    function searchResultsCallback( verses ) {
        if( $.isFunction(displayResultsFn) ) {
          displayResultsFn.call(this, verses);
        }
    };

    // Truncate queries of excessive length
    if (userText.length > 100) {
    	var text = jQuery.trim(userText).substring(0, 100).split(" ").slice(0, -1).join(" ");
    }
    else {
    	var text = userText;
    }

    // User is looking for a single verse
    if (ref = parseVerseRef( text )) {
        $.get("/lookup_user_verse.json", { bk: ref.bk, ch: ref.ch, vs: ref.vs },
            searchResultsCallback, "json" );

    // User is searching for a passage
    } else if (ref = parsePassageRef( text )) {
        $.get("/lookup_user_passage.json", { bk: ref.bk, ch: ref.ch, vs_start: ref.vs_start, vs_end: ref.vs_end },
            searchResultsCallback, "json" );

    // User didn't enter a verse reference ... do a tag search
    } else {
        $.get("/mv_search.json", { searchParams: text },
            searchResultsCallback, "json" );
    }
}

/******************************************************************************
 * Display a passage
 ******************************************************************************/

/******************************************************************************
 * Capitalize strings: romans -> Romans
 ******************************************************************************/
String.prototype.capitalize = function() {
	if (this.charAt(0).match(/[1-3]/)) {
      return this.charAt(0) + this.charAt(1) + this.charAt(2).toUpperCase() + this.slice(3);
	} else {
      return this.charAt(0).toUpperCase() + this.slice(1);
	}
}

/******************************************************************************
 * Substitute abbreviations
 ******************************************************************************/
function unabbreviate(book_name) {
	if(!(book_name.split(" ")[0].match('[^I]'))) { // Check if first "word" contains only I's; then Roman numerals to Arabic numbers
		book_name = book_name.replace("III ", "3 ").replace("II ", "2 ").replace("I ", "1 "); // replace first occurences
	}
	book_index = jQuery.inArray( book_name, BIBLEABBREV );

	if (book_index === -1) { // not a standard abbreviation
		// since it might be a nonstandard abbreviation, let's see if we can find only one possible match with book names
		possibilities = [];
		for (var i = 0; i < BIBLEBOOKS.length; i++) {
			if(BIBLEBOOKS[i].substring(0, book_name.length) == book_name) {
				possibilities.push(BIBLEBOOKS[i]);
			}
		}
		if (possibilities.length == 1) { // nonstandard abbreviation, and only one possibility
			return possibilities[0];
		} else { // already unabbreviated book name (though it may be incorrect)
			return book_name;
		}
	} else { // was a standard abbreviation; return the unabbreviated book name
		return BIBLEBOOKS[book_index];
	}
}

/******************************************************************************
 * Returns true if input is a valid _single_ verse reference
 * Accepts: Romans 8:1
 * Accepts: Romans 8: 1
 * Rejects: Romans 8
 * Rejects: Romans 8:1-3
 ******************************************************************************/
function validVerseRef(verseref) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:(\s)?|(\s?vs\s?))[0-9]+$/i.test(verseref);
}

/******************************************************************************
 * Returns true if input is a valid passage reference

 * Accepts: Romans 8
 * Accepts: Romans 8:
 * Accepts: Romans 8:1-3
 * Accepts: Romans 8: 1-3
 * Rejects: Romans 8:1
 *******************************************************************************/
function validPassageRef(passage) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(((:(\s)?|(\s?vs\s?))[0-9]+(-)[0-9]+)|:)?$/i.test(passage);
}

/******************************************************************************
 * Returns true iff input is a chapter reference

 * Accepts: Romans 8
 * Accepts: Romans 8:
 * Rejects: Romans 8:1
 * Rejects: Romans 8:1-3
 *******************************************************************************/
function validChapterRef(passage) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:)?$/i.test(passage);
}

/******************************************************************************
 * Returns true iff input is a passage reference

 * Accepts: Romans 8:1-3
 * Rejects: Romans 8
 * Rejects: Romans 8:1
 *******************************************************************************/
function validSubChapterPassage(passage) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:|(\s?vs\s?))[0-9]+(-)[0-9]+/i.test(passage);
}

/******************************************************************************
 * Clean up user entered verses
 ******************************************************************************/
function cleanseVerseText( versetext ) {

	versetext = versetext.replace(/—/g, ' — ')    // add spaces around em dash
	                     .replace(/--/g, ' — ')   // replace double dash with em dash
	                     .replace(/\[\w\]/g, " ") // remove footnotes
	                     .replace(/\n/g,' ')      // remove newlines
	                     .replace(/\s{2,}/g,' '); // remove double space
	versetext = $.trim(versetext);                // remove trailing and leading whitespace. Using jQuery's trim() to support IE.

	return versetext;
}

/******************************************************************************
 * Remove special characters to compare user input to correct text
 ******************************************************************************/
scrub_text = function(text) {
    return text.toLowerCase().replace(/[^0-9a-záâãàçéêíóôõúüñαβξδεφγηισκλμνοπθρστυϝωχψζ]+/g, "");
}

/******************************************************************************
 * Blankify a verse
 ******************************************************************************/
function blankifyVerse(versetext, reduction_percentage) {

    var split_text, sort_by_length, text_with_blanks, word_width;

    if  ( reduction_percentage == 0 ) {

    	return versetext;

    }

    else {

	    split_text     = versetext.trim().split(/\s/);
	    sort_by_length = split_text.slice(0);  // make a copy of the original array

	    sort_by_length.sort(function(a, b) {
	        return (a.length < b.length) ? 1 : 0;
	    });

	    // select the longest words to remove
	    sort_by_length.length = Math.round(split_text.length * reduction_percentage / 100);

	    text_with_blanks = split_text.map( function(x) {
	        if ( sort_by_length.indexOf(x) < 0 ) {
	            return x;
	        }
	        else {
	        	// TODO: this line calculates an approximately sized input box for the given word
                // It would be preferable to calculate the exact width of the actual word
	        	word_width = Math.round( x.length * 62) / 100;  // multiply word length by 0.62 and round to one decimal
	            return "<input name='" + x.replace(/'/, '’') + "' class='blank-word' style='width:" + word_width + "em;'>";
	        };
	    });

	    return text_with_blanks.join(" ");
    }

};

/******************************************************************************
 * Parses reference into a book, chapter & verse
 ******************************************************************************/
function parseVerseRef(verseref) {

	// ========== TODO ======================================
	// Handle foreign language book names
	// ======================================================

	var split_text;
	var ch, bk, bi, vs;

	if (validVerseRef(verseref)) {

		// Handle corner cases
		verseref = verseref.replace(/(song of songs)/i, "Song of Songs")
						   .replace(/(psalm )/i,        "Psalms ");

		split_text = verseref.split(/:\s|:|\s/);

		vs = parseInt(split_text.pop());
		ch = parseInt(split_text.pop());
		bk = unabbreviate( split_text.join(' ').capitalize() );
		bi = jQuery.inArray( bk, BIBLEBOOKS );

		if (bi === -1) {
			return false;
		} else {
			return { bk: bk, ch: ch, vs: vs, bi: bi+1};
		};
	} else {
		return false;
	};
}


/******************************************************************************
 * Check whether next review date has passed
 * Note: mv.next_test is a string with format 'yyyy-mm-dd'
 ******************************************************************************/
function mvDue( mv ) {

    var today           = new Date();
    var reviewDateArray = mv.next_test.match(/(\d+)/g);
    var nextReviewDate  = new Date( reviewDateArray[0], reviewDateArray[1]-1, reviewDateArray[2]); // Jan = 0

    return nextReviewDate < today
}

/******************************************************************************
 * Parses passage reference into a book, chapter, start verse & end verse
 ******************************************************************************/
function parsePassageRef(passage) {

	// ========== TODO ======================================
	// Handle foreign language book names
	// ======================================================

	var split_text;
	var ch, bk, bi;
	var vs_start = null;
	var vs_end   = null;

	if (validPassageRef(passage)) {

		// Handle corner cases
		passage = passage.replace(/(song of songs)/i, "Song of Songs")
						 .replace(/(psalm )/i,        "Psalms ")
                         .replace(/\:\s/, ':') // change colon + space to just a colon
						 .replace(/\:$/, '');  // Something like "Romans 8:" -- can happen on Add Verse page as user types

		split_text = passage.split(/:|-|\s/);  /* split on dash, colon or space */

		if (validSubChapterPassage(passage)) {
			vs_end   = parseInt(split_text.pop());
			vs_start = parseInt(split_text.pop());
		}

		ch       = parseInt(split_text.pop());
		bk       = unabbreviate( split_text.join(' ').capitalize() );
		bi       = jQuery.inArray( bk, BIBLEBOOKS );

		if (bi === -1) {
			return false;
		} else {
			return { bk: bk, ch: ch, vs_start: vs_start, vs_end: vs_end, bi: bi+1};
		};

	} else {
		return false;
	};
}

/******************************************************************************
 * Reset scrollable list of verses to the beginning
 ******************************************************************************/
function resetScrollable() {
	var api = $(".scrollable").data("scrollable"); 	// get handle to scrollable API
	api.begin(); 									// use API to move back to the beginning
}


/******************************************************************************
 * Check for completed badges
 ******************************************************************************/
function mvCheckBadgeCompletion() {
	$.getJSON('/badge_quests_check.json', function(quests) {
		if ( quests.length !== 0 ) {
			// Alert user to completion of quests necessary for badges

			// Check for awarded badges
			$.getJSON('/badge_completion_check.json', function(badges) {
				// Alert user to completed badges
				if ( badges.length !== 0 ) {
					for (var i = 0; i < badges.length; i++) {
    					displayAlertMessage("Congratulations! You have been awarded a " + badges[i]["color"] + " " + badges[i]["name"] + " badge.");
					}
				}
			});
		};
	});
}

/******************************************************************************
 * Show an alert
 ******************************************************************************/
function displayAlertMessage(message) {

	var timeOut = 7;

	$('.mvMessageBox').text(message).fadeIn().css('display', 'block');
	setTimeout(function() {
		jQuery('.mvMessageBox').fadeOut().css('display', 'none');
	}, timeOut * 1000);
}

/******************************************************************************
 * All DOM attachments that are common to multiple pages should go here
 ******************************************************************************/
$(document).ready(function() {
	$('input#verse').focus().autocomplete({ source: BIBLEBOOKS });
});

$(document).ajaxStart( function () {
    $('.spinner').show();
});

$(document).ajaxStop( function () {
    $('.spinner').hide();
});
