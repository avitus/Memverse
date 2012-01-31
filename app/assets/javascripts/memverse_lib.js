BIBLEBOOKS = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
	          '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalm', 'Proverbs',
	           'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 
	           'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
	           'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
	           'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
	           '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']

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
		
		if (jQuery.inArray( bk, BIBLEBOOKS ) === -1) {
			return false	
		} else {
			return { bk: bk, ch: ch, vs: vs};						
		}					
	} else {
		return false;
	}
}



