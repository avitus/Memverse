import Foundation

struct SchedulingSnapshot: Equatable {
    var repN: Int
    var efactor: Double
    var testInterval: Int
    var nextTest: String
    var attempts: Int
    var lastTested: String?
}

struct MemverseRecord: Identifiable, Equatable {
    var id: Int
    var userId: Int
    var ref: String
    var text: String
    var translation: String
    var nextTest: String
    var testInterval: Int
    var repN: Int
    var efactor: Double
    var status: String
    var feedback: Bool
    var mnemonic: String
    var attempts: Int
    var lastTested: String?

    var snapshot: SchedulingSnapshot {
        SchedulingSnapshot(
            repN: repN,
            efactor: efactor,
            testInterval: testInterval,
            nextTest: nextTest,
            attempts: attempts,
            lastTested: lastTested
        )
    }

    /// The website allows single-letter entry only when no mnemonic is showing.
    var allowsFirstLetter: Bool {
        mnemonic.isEmpty || mnemonic == "-"
    }

    /// `"-"` and an empty mnemonic mean the website is not showing the hint.
    var showsMnemonic: Bool {
        mnemonic.isEmpty == false && mnemonic != "-"
    }
}

extension MemverseRecord: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ref
        case text
        case tl
        case nextTest = "next_test"
        case testInterval = "test_interval"
        case repN = "rep_n"
        case efactor
        case status
        case feedback
        case mnemonic
        case attempts
        case lastTested = "last_tested"
        case verse
    }

    private struct VerseBody: Decodable {
        var translation: String?
        var text: String?
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        userId = try values.decode(Int.self, forKey: .userId)
        ref = try values.decode(String.self, forKey: .ref)
        let verse = try values.decodeIfPresent(VerseBody.self, forKey: .verse)
        text = try values.decodeIfPresent(String.self, forKey: .text) ?? verse?.text ?? ""
        translation = try values.decodeIfPresent(String.self, forKey: .tl) ?? verse?.translation ?? ""
        nextTest = try Self.decodeDate(values, key: .nextTest)
        testInterval = try values.decode(Int.self, forKey: .testInterval)
        repN = try values.decode(Int.self, forKey: .repN)
        efactor = try Self.decodeDouble(values, key: .efactor)
        status = try values.decodeIfPresent(String.self, forKey: .status) ?? ""
        feedback = try values.decodeIfPresent(Bool.self, forKey: .feedback) ?? true
        mnemonic = try values.decodeIfPresent(String.self, forKey: .mnemonic) ?? ""
        attempts = try values.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        lastTested = try Self.decodeOptionalDate(values, key: .lastTested)
    }

    private static func decodeDouble(_ values: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double {
        if let number = try? values.decode(Double.self, forKey: key) {
            return number
        }
        let text = try values.decode(String.self, forKey: key)
        guard let number = Double(text) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: values, debugDescription: "Expected a number")
        }
        return number
    }

    private static func decodeDate(_ values: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> String {
        if let text = try? values.decode(String.self, forKey: key) {
            return String(text.prefix(10))
        }
        throw DecodingError.dataCorruptedError(forKey: key, in: values, debugDescription: "Expected a date")
    }

    private static func decodeOptionalDate(_ values: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> String? {
        if let text = try values.decodeIfPresent(String.self, forKey: key) {
            return String(text.prefix(10))
        }
        return nil
    }
}

struct UserProfile: Decodable, Equatable {
    var id: Int
    var name: String?
}

struct APIEnvelope<T: Decodable>: Decodable {
    var response: T
}

struct MemversePage: Decodable {
    var response: [MemverseRecord]
    var pagination: PageInfo?

    struct PageInfo: Decodable {
        var pages: Int
    }
}
