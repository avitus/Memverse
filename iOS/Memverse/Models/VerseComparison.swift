import Foundation

/// Word feedback from the website's `verseFeedback` and `scrub_text`.
/// This does not choose the grade. The user still picks 1–5.
enum VerseComparison {
    struct Result: Equatable {
        var feedback: String
        var correct: Bool
        var waiting: Bool
    }

    static func compare(expected: String, guess: String, feedbackEnabled: Bool, allowFirstLetter: Bool) -> Result {
        if guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Result(feedback: "Waiting for you to begin typing...", correct: false, waiting: true)
        }

        let guessWords = splitByWords(guess).map(scrub)
        let rightWords = splitByWords(expected)
        let scrubbedRight = rightWords.map(scrub)
        var feedback = ""
        var sawMismatch = false

        for (index, guessWord) in guessWords.enumerated() {
            guard index < scrubbedRight.count else { break }
            let previous = index > 0 ? guessWords[index - 1] : nil
            let next = index + 1 < guessWords.count ? guessWords[index + 1] : nil
            let right = scrubbedRight[index]
            let firstLetterInUse = guessWords.count >= 2
                && guessWord.count == 1
                && ((previous?.count == 1) || (next?.count == 1))

            if guessWord == right {
                feedback += rightWords[index]
            } else if allowFirstLetter && firstLetterInUse && guessWord == firstLetter(of: right) {
                feedback += rightWords[index]
            } else {
                feedback += "... "
                sawMismatch = true
            }
        }

        let complete = guessWords.count == rightWords.count && !sawMismatch
        if !feedbackEnabled {
            feedback = complete ? "Feedback is off. Correct" : "Feedback is off"
        } else if complete {
            feedback += " Correct"
        }
        return Result(feedback: feedback, correct: complete, waiting: false)
    }

    static func scrub(_ text: String) -> String {
        var result = text.lowercased()
        result = replacing(result, pattern: "[^0-9a-z\\u00BF-\\u1FFF\\u2C00-\\uD7FF]+", with: "")
        result = replacing(result, pattern: "[，一。！？：；（）]+", with: "")
        result = replacing(result, pattern: "[´`͂῾᾿·]+", with: "")
        result = result.replacingOccurrences(of: "ό", with: "ο")
        result = result.replacingOccurrences(of: "ά", with: "α")
        result = result.replacingOccurrences(of: "ἐ", with: "ε")
        result = replacing(result, pattern: "[ῖἱ]", with: "ι")
        return result
    }

    static func splitByWords(_ text: String) -> [String] {
        let pattern = "[-—\\s]*(?:[^\\u4E00-\\u9FFF\\u1100-\\u11FF\\uAC00-\\uD7A3\\s]+|[\\u4E00-\\u9FFF\\u1100-\\u11FF\\uAC00-\\uD7A3][^\\u4E00-\\u9FFF\\u1100-\\u11FF\\uAC00-\\uD7A3\\s]*)\\s*(?:[-—\\s]+$)?"
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    private static func firstLetter(of scrubbed: String) -> String {
        guard let scalar = scrubbed.unicodeScalars.first else { return "" }
        let value = scalar.value
        if (0xAC00...0xD7A3).contains(value) {
            let choseong = 4352 + Int(value - 44032) / 588
            return String(UnicodeScalar(choseong) ?? scalar)
        }
        return String(scalar)
    }

    private static func replacing(_ text: String, pattern: String, with template: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }
}
