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

BOOKS   = [BIBLEBOOKS,  SPANISHBOOKS]
ABBREVS = [BIBLEABBREV, SPANISHABBREV]

/******************************************************************************
 * Accepts abbreviation (or correct book name) in English or Spanish
 * Returns full name of book in English
 ******************************************************************************/
unabbreviate = (book_name) ->

	`if(!(book_name.split(" ")[0].match('[^Ii]'))) { // Check if first "word" contains only I's; then Roman numerals to Arabic numbers
		book_name = book_name.replace(/III /i, "3 ").replace(/II /i, "2 ").replace(/I /i, "1 "); // replace first occurences
	}`

    abbrev_index = (abbrev) ->

        # Try English and Spanish abbreviations
        for language_abbrevs in ABBREVS

            for abbr, index in language_abbrevs

                if abbr == abbrev
                    return index + 1
                end

            end

        end

        # Unknown abbreviation
        0

    other_abbrev_index = (abbrev) ->
        possibilities = []

        for language_books in BOOKS
            for book, index in language_books
                if book[0..book_name.length].toLowerCase() == book_name.toLowerCase()
                    possibilities.push(index)
                end
            end
        end

        if possibilities.length == 1
            possibilities[0]
        else
            0

    if abbrev_index book_name                      # valid standard abbreviation
        return BIBLEBOOKS[abbrev_index book_name]
    else if other_abbrev_index book_name           # valid non-standard abbreviation
        return BIBLEBOOKS[other_abbrev_index book_name]
    else                                           # TODO: Why do we return this? Isn't it invalid?
        return book_name
    end

/******************************************************************************
 * Parses reference into a book, chapter & verse
 ******************************************************************************/
parseVerseRef = (verseref) ->

	// ========== TODO ======================================
	// Handle foreign language book names
	// ======================================================

	var split_text;
	var ch, bk, bi, vs;

	if (validVerseRef(verseref)) {

		// Handle corner cases
		verseref = verseref.replace(/(song of songs)/i, "Song Of Songs")
						   .replace(/(psalm )/i,        "Psalms ");

		split_text = verseref.split(/:\s|:|\s/);

		vs = parseInt(split_text.pop());
		ch = parseInt(split_text.pop());
		bk = unabbreviate( split_text.join(' ') );
		bi = jQuery.inArray( bk, BIBLEBOOKS );

		if (bi === -1) {
			return false;
		} else {
			return { bk: bk, ch: ch, vs: vs, bi: bi+1};
		};
	} else {
		return false;
	};


/******************************************************************************
 * Parses passage reference into a book, chapter, start verse & end verse
 ******************************************************************************/
parsePassageRef = (passage) ->

	// ========== TODO ======================================
	// Handle foreign language book names
	// ======================================================

	var split_text;
	var ch, bk, bi;
	var vs_start = null;
	var vs_end   = null;

	if (validPassageRef(passage)) {

		// Handle corner cases
		passage = passage.replace(/(song of songs)/i, "Song Of Songs")
						 .replace(/(psalm )/i,        "Psalms ")
                         .replace(/\:\s/, ':') // change colon + space to just a colon
						 .replace(/\:$/, '');  // Something like "Romans 8:" -- can happen on Add Verse page as user types

		split_text = passage.split(/:|-|\s/);  /* split on dash, colon or space */

		if (validSubChapterPassage(passage)) {
			vs_end   = parseInt(split_text.pop());
			vs_start = parseInt(split_text.pop());
		}

		ch       = parseInt(split_text.pop());
		bk       = unabbreviate( split_text.join(' ') );
		bi       = jQuery.inArray( bk, BIBLEBOOKS );

		if (bi === -1) {
			return false;
		} else {
			return { bk: bk, ch: ch, vs_start: vs_start, vs_end: vs_end, bi: bi+1};
		};

	} else {
		return false;
	};
