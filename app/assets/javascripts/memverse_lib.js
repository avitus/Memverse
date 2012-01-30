/******************************************************************************
 * Returns true if input is a valid verse reference
 ******************************************************************************/
function validVerseRef(verseref) {
    return /([0-3]?\s+)?[a-záéíóúüñ]+\s+[0-9]+(:|(\s?vs\s?))[0-9]+/i.test(verseref);
}

/******************************************************************************
 * Parses reference into a book, chapter & verse
 ******************************************************************************/
function parseVerseRef(verseref) {

	var split_text
	
	if (validVerseRef(verseref)) {
		
		split_text = verseref.split(/:|\s/);
		
		vs = parseInt(split_text.pop());
		ch = parseInt(split_text.pop());
		bk = split_text.join(' ')
		
		return { bk: bk, ch: ch, vs: vs};
					
	} else {
		
		return false;
		
	}
}
