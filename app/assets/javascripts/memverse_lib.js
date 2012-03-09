BIBLEBOOKS = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
	          '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
	           'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 
	           'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
	           'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
	           'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
	           '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']

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
 * Returns true if input is a valid verse reference
 * Accepts: Romans 8:1
 * Rejects: Romans 8
 * Rejects: Romans 8:1-3
 ******************************************************************************/
function validVerseRef(verseref) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:|(\s?vs\s?))[0-9]+$/i.test(verseref);
}

/******************************************************************************
 * Returns true if input is a valid verse reference

 * Accepts: Romans 8
 * Accepts: Romans 8:1-3
 * Rejects: Romans 8:1
 *******************************************************************************/
function validPassageRef(passage) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+((:|(\s?vs\s?))[0-9]+(-)[0-9]+)?$/i.test(passage);	
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
	                     .replace(/\s{2,}/g,' ')  // remove double spaces
						 .trim();                 // remove trailing and leading whitespace
						 
	return versetext;
}

/******************************************************************************
 * Parses reference into a book, chapter & verse
 ******************************************************************************/
function parseVerseRef(verseref) {
		
	// ========== TODO ======================================
	// Handle: abbreviations, foreign language book names
	// ======================================================	

	var split_text;
	var ch, bk, bi, vs;
		
	if (validVerseRef(verseref)) {
		
		// Handle corner cases
		verseref = verseref.replace(/(song of songs)/i, "Song of Songs")
						   .replace(/(psalm )/i,        "Psalms ");
			
		split_text = verseref.split(/:|\s/);
		
		vs = parseInt(split_text.pop());
		ch = parseInt(split_text.pop());
		bk = split_text.join(' ').capitalize();
		bi = jQuery.inArray( bk, BIBLEBOOKS );
				
		if (bi === -1) {
			return false	
		} else {
			return { bk: bk, ch: ch, vs: vs, bi: bi+1};						
		};		
	} else {
		return false;
	};
}

/******************************************************************************
 * Parses passage reference into a book, chapter, start verse & end verse
 ******************************************************************************/
function parsePassageRef(passage) {
		
	// ========== TODO ======================================
	// Handle: abbreviations, foreign language book names
	// ======================================================	

	var split_text;
	var ch, bk, bi;
	var vs_start = null;
	var vs_end   = null;
	
	if (validPassageRef(passage)) {
		
		// Handle corner cases
		passage = passage.replace(/(song of songs)/i, "Song of Songs")
						 .replace(/(psalm )/i,        "Psalms ");
			
		split_text = passage.split(/:|-|\s/);  /* split on dash, colon or space */
									 
		if (validSubChapterPassage(passage)) {
			vs_end   = parseInt(split_text.pop());
			vs_start = parseInt(split_text.pop());	
		} 
								
		ch       = parseInt(split_text.pop());
		bk       = split_text.join(' ').capitalize();
		bi       = jQuery.inArray( bk, BIBLEBOOKS );
				
		if (bi === -1) {
			return false	
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
 * All DOM attachments that are common to multiple pages should go here
 ******************************************************************************/
$(document).ready(function() {
	
	// Add spinners where needed to show activity
	$('.spinner')
		.ajaxStart(function() {
	        $(this).show();
	    })
		.ajaxStop(function() {
	        $(this).hide();
	});

	$('#verse').focus().autocomplete({ source: ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
                '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalm', 'Proverbs',
                'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 
                'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
                'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
                'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
                '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']						
	});	
	
});

