import Foundation

/// Which due row should open after the server accepts a grade.
enum ReviewAdvance {
    static func selectionAfterSave(previousIDs: [Int], savedID: Int, remainingIDs: [Int]) -> Int? {
        guard remainingIDs.isEmpty == false else { return nil }
        guard let index = previousIDs.firstIndex(of: savedID) else { return remainingIDs.first }
        let after = previousIDs[previousIDs.index(after: index)...]
        if let next = after.first(where: { remainingIDs.contains($0) }) {
            return next
        }
        return remainingIDs.first(where: { $0 != savedID }) ?? remainingIDs.first
    }
}
