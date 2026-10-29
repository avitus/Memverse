import Foundation

enum ReviewSaveOutcome: Equatable {
    case saved(MemverseRecord)
    case notSaved
    case ambiguous
    case rejected
}

enum ReviewSave {
    static func changed(_ before: SchedulingSnapshot, _ after: SchedulingSnapshot) -> Bool {
        before.repN != after.repN
            || abs(before.efactor - after.efactor) > 0.000_1
            || before.testInterval != after.testInterval
            || before.nextTest != after.nextTest
            || before.attempts != after.attempts
            || before.lastTested != after.lastTested
    }

    /// A timed-out write is not proof of failure. Compare the server record
    /// with the pre-submit snapshot. Retry only when the record is unchanged.
    static func interpretTransportFailure(before: SchedulingSnapshot, confirmed: MemverseRecord?) -> ReviewSaveOutcome {
        guard let confirmed else { return .ambiguous }
        if changed(before, confirmed.snapshot) {
            return .saved(confirmed)
        }
        return .notSaved
    }
}
