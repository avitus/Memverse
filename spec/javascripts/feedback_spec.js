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
})
