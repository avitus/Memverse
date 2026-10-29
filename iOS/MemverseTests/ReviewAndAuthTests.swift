import Foundation
import Testing
@testable import Memverse

struct PasswordGrantTests {
    @Test func theTokenRequestUsesTheExistingClient() throws {
        let request = OAuthEndpoints.passwordGrantRequest(
            baseURL: URL(string: "https://www.memverse.com")!,
            username: "person@example.com",
            password: "secret-value"
        )
        #expect(request.url?.path == "/oauth/token")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == MemverseConfiguration.basicAuthorization)
        let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: String]
        #expect(body?["grant_type"] == "password")
        #expect(body?["client_id"] == MemverseConfiguration.oauthClientID)
        #expect(body?["username"] == "person@example.com")
        #expect(body?["password"] == "secret-value")
        #expect(body?["client_secret"] == nil)
        #expect(body?["scope"] == nil)
    }
}

struct DueQueueTests {
    @Test func pendingAndFutureVersesStayOutOfTheQueue() {
        let today = "2026-10-21"
        let due = AppModel.fixture
        var later = due
        later.id = 2
        later.nextTest = "2026-10-22"
        var pending = due
        pending.id = 3
        pending.status = "Pending"
        let queue = DueQueue.due([later, pending, due], on: today)
        #expect(queue.map(\.id) == [1])
    }
}

struct ReviewAdvanceTests {
    @Test func theFollowingDueVerseOpensNext() {
        let next = ReviewAdvance.selectionAfterSave(previousIDs: [4, 9, 12], savedID: 4, remainingIDs: [9, 12])
        #expect(next == 9)
    }

    @Test func aFinishedQueueDoesNotSelectAnything() {
        let next = ReviewAdvance.selectionAfterSave(previousIDs: [4], savedID: 4, remainingIDs: [])
        #expect(next == nil)
    }

    @Test func aVerseThatStaysDueOpensAgainWhenItIsTheOnlyOne() {
        let next = ReviewAdvance.selectionAfterSave(previousIDs: [4], savedID: 4, remainingIDs: [4])
        #expect(next == 4)
    }
}

struct MnemonicHintTests {
    @Test func aDashOrBlankHidesTheHint() {
        var record = AppModel.fixture
        record.mnemonic = "-"
        #expect(record.showsMnemonic == false)
        record.mnemonic = ""
        #expect(record.showsMnemonic == false)
    }

    @Test func firstLettersAreTheHintAndNotTheVerse() {
        var record = AppModel.fixture
        record.mnemonic = "A b c"
        #expect(record.showsMnemonic)
        #expect(record.mnemonic != record.text)
    }
}

struct ReviewSaveTests {
    @Test func anUnchangedRecordWasNotSaved() {
        let record = AppModel.fixture
        let outcome = ReviewSave.interpretTransportFailure(before: record.snapshot, confirmed: record)
        #expect(outcome == .notSaved)
    }

    @Test func aChangedRecordCountsAsSaved() {
        var record = AppModel.fixture
        record.attempts = 1
        record.nextTest = "2026-10-24"
        let outcome = ReviewSave.interpretTransportFailure(before: AppModel.fixture.snapshot, confirmed: record)
        if case .saved(let saved) = outcome {
            #expect(saved.nextTest == "2026-10-24")
        } else {
            Issue.record("Expected the changed record to count as saved")
        }
    }

    @Test func aMissingConfirmationStaysAmbiguous() {
        let outcome = ReviewSave.interpretTransportFailure(before: AppModel.fixture.snapshot, confirmed: nil)
        #expect(outcome == .ambiguous)
    }
}

struct MemverseDecodingTests {
    @Test func decodesTheRailsEnvelopeIncludingAStringEfactor() throws {
        let json = """
        {"response":{"id":7,"user_id":3,"ref":"Psalm 117:1","text":"Praise the LORD.","tl":"NIV","next_test":"2026-10-24","test_interval":4,"rep_n":2,"efactor":"2.1","status":"Learning","feedback":true,"mnemonic":"","attempts":1,"last_tested":"2026-10-20","verse":{"id":9,"translation":"NIV","text":"Praise the LORD.","book":"Psalms","chapter":117,"versenum":1}},"count":1}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(APIEnvelope<MemverseRecord>.self, from: json)
        #expect(envelope.response.efactor == 2.1)
        #expect(envelope.response.translation == "NIV")
        #expect(envelope.response.attempts == 1)
        #expect(envelope.response.nextTest == "2026-10-24")
    }

    @Test func profileDecodingIgnoresCredentialFields() throws {
        let json = """
        {"response":{"id":4,"name":"Synthetic","email":"s@example.com","encrypted_password":"secret","reset_password_token":"secret"}}
        """.data(using: .utf8)!
        let envelope = try JSONDecoder().decode(APIEnvelope<UserProfile>.self, from: json)
        #expect(envelope.response == UserProfile(id: 4, name: "Synthetic"))
    }
}

struct APIClientTests {
    @Test func aTimeoutIsAmbiguousAndOtherFailuresAreNot() {
        #expect(APIClient.classify(URLError(.timedOut)) == .transportAmbiguous)
        #expect(APIClient.classify(URLError(.networkConnectionLost)) == .transportAmbiguous)
        #expect(APIClient.classify(URLError(.notConnectedToInternet)) == .transportFailed)
        #expect(APIClient.classify(URLError(.cancelled)) == .cancelled)
    }
}
