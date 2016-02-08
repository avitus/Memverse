describe("Feedback", function() {
	it("should be correct even with incorrect punctuation", function() {
		expect(verseFeedback(
			"And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",	// correct text
			"And after he became the father- of Enosh Seth lived: 807 years and had other sons and. daughters",	// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("does not give away complete number when only first numeral has been provided", function() {
		expect(verseFeedback(
			"And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",	// correct text
			"And after he became the father of Enosh, Seth lived 8",											// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And after he became the father of Enosh, Seth lived ... ',
			correct  : false
		})
	});

	it("does give number when number is correct", function() {
		expect(verseFeedback(
			"And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",	// correct text
			"And after he became the father of Enosh, Seth lived 807",											// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And after he became the father of Enosh, Seth lived 807 ',
			correct  : false
		})
	});

	it("should show quotation mark", function() {
		expect(verseFeedback(
			'And he said, "Behold, I am making a covenant. Before all your people I will do marvels, such as have not been created in all the earth or in any nation. And all the people among whom you are shall see the work of the LORD, for it is an awesome thing that I will do with you.',	// correct text
			'and he said behold i am making a covenant.',														// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And he said, "Behold, I am making a covenant. ',
			correct  : false
		})
	});

	it("should not accept Spanish without special characters", function() {
		expect(verseFeedback(
			'Por medio de él todas las cosas fueron creadas; sin él, nada de lo creado llegó a existir.',	// correct text
			'Por medio de l todas las cosas fueron creadas; sin él',										// user guess
			true																							// feedback enabled
		)).toEqual({
			feedtext : 'Por medio de ... todas las cosas fueron creadas; sin él, ',
			correct  : false
		})
	});

	it("should support Portuguese", function() {
		expect(verseFeedback(
			'E fez Deus a expansão, e fez separação entre as águas que estavam debaixo da expansão e as águas que estavam sobre a expansão; e assim foi.',	// correct text
			'E fez Deus a expansao, e fez separacão entre as águas que estavam debaixo da expanso',															// user guess
			true																																			// feedback enabled
		)).toEqual({
			feedtext : 'E fez Deus a ... e fez ... entre as águas que estavam debaixo da ... ',
			correct  : false
		})
	});

	it("should support all sorts of languages", function() {
		expect(verseFeedback(
			"구결口訣 향찰鄕札 이두吏讀",	// correct text
			"구결口訣 향찰鄕札 이讀",		// user guess
			true						// feedback enabled
		)).toEqual({
			feedtext : '구결口訣 향찰鄕札 이... ',
			correct  : false
		})
	});

	it("should accept first letter if mnemonic disabled", function() {
		expect(verseFeedback(
			'For God so loved the world that he gave his one and only Son',		// correct text
			'F G s l t w t h g h o a o s ',										// user guess
			true,																// feedback
			true																// allow first-letter
		)).toEqual({
			feedtext : 'For God so loved the world that he gave his one and only Son<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("should accept accented first letters if mnemonic disabled", function() {
		expect(verseFeedback(
			'En él estaba la vida, y la vida era la luz de los hombres.',		// correct text
			'E é e l v y l v e l l d l h.',										// user guess
			true,																// feedback
			true																// allow first-letter
		)).toEqual({
			correct  : true,
			feedtext : 'En él estaba la vida, y la vida era la luz de los hombres.<div id="matchbox"><span>Correct</span></div>',
		})
	});

	it("should recognize last first-letter without a subsequent space or punctuation mark", function() {
		expect(verseFeedback(
			'This is a test.',		// correct text
			'T i a t.',				// user guess
			true,					// feedback
			true					// allow first-letter
		)).toEqual({
			feedtext : 'This is a test.<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("should accept some complete words in text that's primarily first letters", function() {
		expect(verseFeedback(
			'This is simply a test to see whether the first-letter and complete words functionality works',		// correct text
			'T i s a tesT 2 s w t f a c words functionlality works.',											// user guess
			true,																								// feedback
			true																								// allow first-letter
		)).toEqual({
			feedtext : 'This is simply a test ... see whether the first-letter and complete words ... works',
			correct  : false
		})
	});

	it("should not give feedback if disabled", function() {
		expect(verseFeedback(
			'This is a test',		// correct text
			'T i',					// user guess
			false,					// feedback
			true					// allow first-letter
		)).toEqual({
			feedtext : '< Feedback disabled >',
			correct  : false
		})
	});

	it("should not give feedback if disabled but still say if correct", function() {
		expect(verseFeedback(
			'This is a test.',		// correct text
			'T i a test',			// user guess
			false,					// feedback
			true					// allow first-letter
		)).toEqual({
			feedtext : '< Feedback disabled ><div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("should give ... to an incorrect first first letter even when first letter is disabled", function() {
		expect(verseFeedback(
			'This is a test',		// correct text
			'T',					// user guess
			true,					// feedback
			true					// allow first-letter
		)).toEqual({
			feedtext : '... ',
			correct  : false
		})
	});

	it("should detect any two subsequent single letters as first letters", function() {
		expect(verseFeedback(
			'This is an interesting test.',		// correct text
			'This is a i test',					// user guess
			true,					// feedback
			true					// allow first-letter
		)).toEqual({
			feedtext : 'This is an interesting test.<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("handles hyphens at the end", function() {
		expect(verseFeedback(
			"This is a verse with a hyphen at the end -",	// correct text
			"This is a verse with a hyphen at the end",		// user guess
			true											// feedback enabled
		)).toEqual({
			feedtext : 'This is a verse with a hyphen at the end -<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("handles dashes at the end", function() {
		expect(verseFeedback(
			"This is a verse with a dash at the end —",		// correct text
			"This is a verse with a dash at the end",		// user guess
			true											// feedback enabled
		)).toEqual({
			feedtext : 'This is a verse with a dash at the end —<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});

	it("ignores Greek diacritics", function() {
		expect(verseFeedback(
			"In the beginning άόό ό ῖἱ ῖ ἱ",		// correct text
			"I´`͂῾᾿n the beginning αοο ο ιι ι ι",	// user guess
			true									// feedback enabled
		)).toEqual({
			feedtext : 'In the beginning άόό ό ῖἱ ῖ ἱ<div id="matchbox"><span>Correct</span></div>',
			correct  : true
		})
	});
	
	it("accepts Korean input", function() {
		expect(verseFeedback(
			"그가 태초에 하나님과 함께 계셨고",			// correct text
			"그가 태초에 하가님과 함께 계셨고",			// user guess
			true									//feedback enabled
		)).toEqual({
			feedtext : '그가 태초에 하... 님과 함께 계셨고',
			correct: false
		})
	});
	
	it('accepts Korean "first letters"', function() {
		expect(verseFeedback(
			"모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못하더니",// correct text
			"모든 ᄉᄅ이 죄를 범하ᄋᄋᄆᄒ나님의 영광에 ᄋᄅᄌᄆᄒᄃᄂ",	// user guess
			true,													//feedback enabled
			true													//allow first letter
		)).toEqual({
			feedtext : '모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못하더니<div id="matchbox"><span>Correct</span></div>',
			correct: true
		})
	});

})
