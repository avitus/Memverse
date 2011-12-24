describe("Feedback", function() {
	it("should be correct even with incorrect punctuation", function() {
		expect(versefeedback(
			"And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",	// correct text
			"And after he became the father- of Enosh Seth lived: 807 years and had other sons and. daughters",	// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters. <div id="matchbox"><p>Correct</p></div>',
			correct  : true
		})
	});
	
	it("does not give away complete number when only first numeral has been provided", function() {
		expect(versefeedback(
			"And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",	// correct text
			"And after he became the father of Enosh, Seth lived 8",											// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And after he became the father of Enosh, Seth lived ... ',
			correct  : false
		})
	});
	
	it("does give number when number is correct", function() {
		expect(versefeedback(
			"And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",	// correct text
			"And after he became the father of Enosh, Seth lived 807",											// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And after he became the father of Enosh, Seth lived 807 ',
			correct  : false
		})
	});
	
	it("should show quotation mark", function() {
		expect(versefeedback(
			'And he said, "Behold, I am making a covenant. Before all your people I will do marvels, such as have not been created in all the earth or in any nation. And all the people among whom you are shall see the work of the LORD, for it is an awesome thing that I will do with you.',	// correct text
			'and he said behold i am making a covenant.',											// user guess
			true																								// feedback enabled
		)).toEqual({
			feedtext : 'And he said, "Behold, I am making a covenant. ',
			correct  : false
		})
	});
})
