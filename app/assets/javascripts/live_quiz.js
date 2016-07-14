setupMCQ = function(q_option_a, q_option_b, q_option_c, q_option_d, mc_answer, q_num){
	var q = "q" + q_num + "_";
	output = ["<ul class='mcq'>",
				"<li><input type='radio' name='mcq' value='a' id='"+q+"opt_a' /> <label for='"+q+"opt_a'>(A) " + q_option_a + "</label></li>",
				"<li><input type='radio' name='mcq' value='b' id='"+q+"opt_b' /> <label for='"+q+"opt_b'>(B) " + q_option_b + "</label></li>",
				"<li><input type='radio' name='mcq' value='c' id='"+q+"opt_c' /> <label for='"+q+"opt_c'>(C) " + q_option_c + "</label></li>",
				"<li><input type='radio' name='mcq' value='d' id='"+q+"opt_d' /> <label for='"+q+"opt_d'>(D) " + q_option_d + "</label></li>",
			"</ul>",
			"<input type='submit' value='Answer!' id='submit-answer' class='button-link'>"]

	return output.join("");
};

/******************************************************************************
 * Calculate Levenshtein distance
 ******************************************************************************/
function calculate_levenshtein_distance(s, t) {
  var m = s.length + 1, n = t.length + 1;
  var i, j;

  // for all i and j, d[i,j] will hold the Levenshtein distance between
  // the first i words of s and the first j words of t;
  // note that d has (m+1)x(n+1) values
  var d = [];

  for (i = 0; i < m; i++) {
	d[i] = [i]; // the distance of any first array to an empty second array
  }
  for (j = 0; j < n; j++) {
	d[0][j] = j; // the distance of any second array to an empty first array
  }

  for (j = 1; j < n; j++) {
	for (i = 1; i < m; i++) {
	  if (s[i - 1] === t[j - 1]) {
		d[i][j] = d[i-1][j-1];           // no operation required
	  } else {
		d[i][j] = Math.min(
					d[i - 1][j] + 1,     // a deletion
					d[i][j - 1] + 1,     // an insertion
					d[i - 1][j - 1] + 1  // a substitution
				  );
	  }
	}
  }

  return d[m - 1][n - 1];
}

/******************************************************************************
 * Score a recitation [Max 10 points]
 ******************************************************************************/
function scoreRecitation(versetext, usertext) {

	var score, msg;

	// Convert to lowercase; remove anything that is not a-z and remove extra spaces
	// Do I need to use unescape because of quotation marks? Time will tell...
	user    = $.trim(usertext.toLowerCase().replace(/[^a-z ]|\s-|\s—/g, '').replace(/\s+/g, " "));
	correct = $.trim(versetext.toLowerCase().replace(/[^a-z ]|\s-|\s—/g, '').replace(/\s+/g, " "));

	if (user == "") {
		alert('Please recite the verse. You clicked "Submit" without any words in the box.')
		return false;
	}

	user_words  = user.split(" ");
	right_words = correct.split(" ");

	score = 10 - (calculate_levenshtein_distance(right_words, user_words));

	if (score < 0) {score = 0;} // Prevents score from being less than 0.

	if (score == 10) {
		msg = "You answered perfectly and scored 10 points! Good job.";
	}
	else if (score >= 1) {
		msg = "Although that wasn't perfect, you still received " + score + " points. Keep trying!";
	}
	else {
		msg = "I'm sorry, but that was not correct.";
	}

	return { score: score, msg: msg };
}

/******************************************************************************
 * Score a reference recall [Max = 10 points]
 ******************************************************************************/
function scoreReference(verseref, userref) {

	var score, msg;

	user    = $.trim(userref.toLowerCase().replace(/\s+/g, " "));
	correct = $.trim(verseref.toLowerCase().replace(/\s+/g, " "));

	// handle corner cases
	// note: lowercase
	user = user.replace(/(song of songs)/i, "song of songs")
			   .replace(/(psalm )/i,        "psalms ");

	correct = correct.replace(/(song of songs)/i, "song of songs")
					 .replace(/(psalm )/i,        "psalms ");

	user_book  = user.substring(0,parseInt(user.lastIndexOf(' '))+1);
	right_book = correct.substring(0,parseInt(correct.lastIndexOf(' '))+1);

	user_chapter  = user.substring(parseInt(user.lastIndexOf(' '))+1,user.indexOf(':'));
	right_chapter = correct.substring(parseInt(correct.lastIndexOf(' '))+1,correct.indexOf(':'));

	user_verse  = user.substring(parseInt(user.indexOf(':'))+1);
	right_verse = correct.substring(parseInt(correct.indexOf(':'))+1);

	if ( user_book == "" || user_chapter == "" || user_verse == "" || user.indexOf(':') == "-1") {
		alert("Please format your reference answer as Book Chapter:Verse (for example, Genesis 1:1-2) and try again.\n\nIf you are unsure of part of the reference, just take your best guess. Thank you!");
		return false;
	}

	score = 0;

	if (user_book    == right_book)    {score = score + 2;}
	if (user_chapter == right_chapter) {score = score + 3;}
	if (user_verse   == right_verse)   {score = score + 5;}

	if (score == 10) {
		msg = "You answered perfectly and scored 10 points! Good job.";
	} else if (score >= 1) {
		msg = "Although that wasn't perfect, you still received " + score + " points. Keep trying! The correct reference was " + verseref + " (you entered " + userref + ").";
	} else {
		msg = "Sorry, but that was not correct. The correct reference was " + verseref + ".";
	}

	return { score: score, msg: msg };
}

/******************************************************************************
 * Score a multiple choice question [Max = 10 points]
 ******************************************************************************/
function scoreMCQ(questionAnswer, userAnswer){ // userAnswer will be a, b, c, or d, unless it's empty
	score = ( userAnswer.toUpperCase() == questionAnswer.toUpperCase() ) ? 10 : -2;
	if ( score == 10 ) {
		msg = "Congratulations; that was perfect!";
	} else {
		msg = "Sorry, but your choice (" + userAnswer.toUpperCase() + ") was not correct. The correct answer was (" + questionAnswer.toUpperCase() + ").";
	}

	return { score: score, msg: msg };
}

/******************************************************************************
 * Score based on question type
 ******************************************************************************/
function getScore(questionAnswer, userAnswer, questionType) {

	switch(questionType) {
		case 'recitation':
			return scoreRecitation(questionAnswer, userAnswer);
		break;

		case 'reference':
			return scoreReference(questionAnswer, userAnswer);
		break;

		case 'mcq':
			return scoreMCQ(questionAnswer, userAnswer);
		break;

		default:
			return 0

	}

}


