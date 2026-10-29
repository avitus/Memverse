import Foundation

/// The website's 1–5 self-grade. The number is what `Memverse#supermemo` stores.
enum ReviewGrade: Int, CaseIterable, Identifiable {
    case noIdea = 1
    case familiar = 2
    case difficult = 3
    case hesitation = 4
    case perfect = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .noIdea: "Don't Know - No Idea"
        case .familiar: "Don't Know - Familiar"
        case .difficult: "Remembered - Difficult"
        case .hesitation: "Remembered - Hesitation"
        case .perfect: "Remembered - Perfect"
        }
    }
}
