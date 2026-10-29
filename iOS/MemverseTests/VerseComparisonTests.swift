import Testing
@testable import Memverse

struct VerseComparisonTests {
    @Test func punctuationDoesNotChangeACompleteMatch() {
        let result = VerseComparison.compare(
            expected: "And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",
            guess: "And after he became the father- of Enosh Seth lived: 807 years and had other sons and. daughters",
            feedbackEnabled: true,
            allowFirstLetter: false
        )
        #expect(result.correct)
        #expect(result.feedback.contains("Correct"))
        #expect(result.feedback.contains("Enosh, Seth"))
    }

    @Test func aPartialNumberIsNotTheWholeNumber() {
        let result = VerseComparison.compare(
            expected: "And after he became the father of Enosh, Seth lived 807 years and had other sons and daughters.",
            guess: "And after he became the father of Enosh, Seth lived 8",
            feedbackEnabled: true,
            allowFirstLetter: false
        )
        #expect(!result.correct)
        #expect(result.feedback.contains("..."))
        #expect(!result.feedback.contains("807"))
    }

    @Test func feedbackOffDoesNotEchoTheWords() {
        let result = VerseComparison.compare(
            expected: "Alpha bravo charlie.",
            guess: "alpha",
            feedbackEnabled: false,
            allowFirstLetter: false
        )
        #expect(result.feedback == "Feedback is off")
        #expect(!result.feedback.contains("Alpha"))
    }

    @Test func anEmptyGuessWaits() {
        let result = VerseComparison.compare(
            expected: "Alpha bravo charlie.",
            guess: "   ",
            feedbackEnabled: true,
            allowFirstLetter: false
        )
        #expect(result.waiting)
        #expect(!result.correct)
    }
}
