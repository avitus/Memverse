import Foundation

struct MemverseAPI {
    var client: APIClient

    func profile() async throws -> UserProfile {
        let envelope = try await client.get("api/v1/me", as: APIEnvelope<UserProfile>.self)
        return envelope.response
    }

    func dueVerses() async throws -> [MemverseRecord] {
        var page = 1
        var pageCount = 1
        var records: [MemverseRecord] = []
        while page <= pageCount && page <= 100 {
            let envelope = try await client.get(
                "api/v1/memverses",
                query: ["page": String(page)],
                as: MemversePage.self
            )
            records.append(contentsOf: envelope.response)
            pageCount = max(envelope.pagination?.pages ?? 1, 1)
            page += 1
        }
        return DueQueue.due(records, on: DueQueue.today())
    }

    func memverse(id: Int) async throws -> MemverseRecord {
        let envelope = try await client.get("api/v1/memverses/\(id)", as: APIEnvelope<MemverseRecord>.self)
        return envelope.response
    }

    func recordReview(id: Int, grade: ReviewGrade, before: SchedulingSnapshot) async -> ReviewSaveOutcome {
        do {
            let envelope = try await client.put(
                "api/v1/memverses/\(id)",
                query: ["q": String(grade.rawValue)],
                as: APIEnvelope<MemverseRecord>.self
            )
            return .saved(envelope.response)
        } catch APIError.transportAmbiguous {
            let confirmed = try? await memverse(id: id)
            return ReviewSave.interpretTransportFailure(before: before, confirmed: confirmed)
        } catch APIError.cancelled {
            return .ambiguous
        } catch {
            return .rejected
        }
    }
}
