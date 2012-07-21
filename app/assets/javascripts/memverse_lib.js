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
	book_index = jQuery.inArray( book_name, BIBLEABBREV );
	if (book_index === -1) {
		return book_name;
	} else {
		return BIBLEBOOKS[book_index];						
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
 * Accepts: Romans 8:
 * Accepts: Romans 8:1-3
 * Rejects: Romans 8:1
 *******************************************************************************/
function validPassageRef(passage) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(((:|(\s?vs\s?))[0-9]+(-)[0-9]+)|:)?$/i.test(passage);
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
		bk = unabbreviate( split_text.join(' ').capitalize() );
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
						 .replace(/(psalm )/i,        "Psalms ")
						 .replace(/\:$/, ''); // Something like "Romans 8:" -- can happen on Add Verse page as user types
		
		split_text = passage.split(/:|-|\s/);  /* split on dash, colon or space */
		
		if (validSubChapterPassage(passage)) {
			vs_end   = parseInt(split_text.pop());
			vs_start = parseInt(split_text.pop());	
		} 
		
		ch       = parseInt(split_text.pop());
		bk       = unabbreviate( split_text.join(' ').capitalize() );
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

	// Add spinners where needed to show activity
	$('.spinner')
		.ajaxStart(function() {
	        $(this).show();
	    })
		.ajaxStop(function() {
	        $(this).hide();
	});

	$('input#verse').focus().autocomplete({ source: BIBLEBOOKS });

});

