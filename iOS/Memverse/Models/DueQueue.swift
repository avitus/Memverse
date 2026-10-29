import Foundation

enum DueQueue {
    /// `next_test` is a calendar date. The live list has no due filter, so the
    /// queue keeps the same rule as the previous iOS app: not Pending, and
    /// `next_test` on or before the phone's local date.
    static func today(calendar: Calendar = .current, now: Date = Date()) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func due(_ records: [MemverseRecord], on day: String) -> [MemverseRecord] {
        records.filter { $0.status != "Pending" && $0.nextTest <= day }
    }
}
