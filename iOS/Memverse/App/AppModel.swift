import Foundation

@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case signedOut
        case signingIn
        case loading
        case ready
        case failed(String)
        case unavailable(String)
    }

    var phase: Phase = .signedOut
    var profile: UserProfile?
    var session: [MemverseRecord] = []
    var statusMessage: String?
    /// The due row to open after a grade leaves the current one.
    var preferredSelection: Int?
    var isSubmitting = false

    private let auth: AuthService
    private let api: MemverseAPI
    private var usesFixture = false

    init() {
        let store = KeychainTokenStore()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestingResetKeychain") {
            try? store.clear()
        }
        #endif
        let urlSession = URLSession(configuration: .ephemeral)
        let baseURL = MemverseConfiguration.apiBaseURL
        let auth = AuthService(
            baseURL: baseURL,
            clientID: MemverseConfiguration.oauthClientID,
            session: urlSession,
            store: store
        )
        self.auth = auth
        api = MemverseAPI(client: APIClient(
            baseURL: baseURL,
            session: urlSession,
            accessToken: { await auth.accessToken() },
            refresh: { try await auth.forceRefresh() }
        ))

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestingQueue") {
            usesFixture = true
            phase = .ready
            profile = UserProfile(id: 1, name: "Synthetic")
            session = [Self.fixture]
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestingSignedOut") {
            usesFixture = true
            phase = .signedOut
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-uiTestingLoadFailed") {
            usesFixture = true
            phase = .unavailable("Memverse could not load today's review.")
            profile = UserProfile(id: 1, name: "Synthetic")
            return
        }
        #endif
    }

    func start() async {
        guard usesFixture == false else { return }
        guard phase == .signedOut else { return }
        if await auth.accessToken() == nil {
            phase = .signedOut
            return
        }
        await reload()
    }

    func signIn(email: String, password: String) async {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.isEmpty == false, password.isEmpty == false else { return }
        phase = .signingIn
        statusMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
            await reload()
        } catch AuthError.tokenRejected {
            phase = .failed("The email or password was not accepted.")
        } catch APIError.transportFailed, APIError.transportAmbiguous {
            phase = .failed("Memverse could not be reached. You can try again.")
        } catch {
            phase = .failed("Sign-in did not finish. You can try again.")
        }
    }

    func reload() async {
        guard usesFixture == false else { return }
        guard isSubmitting == false else { return }
        phase = .loading
        statusMessage = nil
        preferredSelection = nil
        do {
            try await auth.refreshIfNeeded()
            profile = try await api.profile()
            session = try await api.dueVerses()
            phase = .ready
        } catch APIError.unauthorized {
            try? auth.store.clear()
            profile = nil
            session = []
            phase = .signedOut
        } catch {
            phase = .unavailable("Memverse could not load today's review.")
        }
    }

    func logout() async {
        guard isSubmitting == false else {
            statusMessage = "Wait until the grade finishes saving, then sign out."
            return
        }
        guard usesFixture == false else {
            phase = .signedOut
            session = []
            statusMessage = nil
            preferredSelection = nil
            return
        }
        do {
            try await auth.logout()
            profile = nil
            session = []
            statusMessage = nil
            preferredSelection = nil
            phase = .signedOut
        } catch {
            statusMessage = "Sign-out did not reach Memverse. You are still signed in."
        }
    }

    func submit(_ record: MemverseRecord, grade: ReviewGrade) async -> ReviewSaveOutcome {
        guard isSubmitting == false else { return .rejected }
        guard usesFixture == false else {
            statusMessage = "Saved. Next review \(record.nextTest)."
            return .saved(record)
        }
        isSubmitting = true
        defer { isSubmitting = false }
        let outcome = await api.recordReview(id: record.id, grade: grade, before: record.snapshot)
        switch outcome {
        case .saved(let saved):
            statusMessage = "Saved. Next review \(saved.nextTest)."
            let previousIDs = session.map(\.id)
            session = (try? await api.dueVerses()) ?? session.filter { $0.id != saved.id }
            preferredSelection = ReviewAdvance.selectionAfterSave(
                previousIDs: previousIDs,
                savedID: saved.id,
                remainingIDs: session.map(\.id)
            )
        case .notSaved:
            statusMessage = "That grade was not saved. You can try again."
        case .ambiguous:
            statusMessage = "Memverse did not confirm this grade. It was not sent again."
        case .rejected:
            statusMessage = "Memverse could not save that grade."
        }
        return outcome
    }

    static let fixture = MemverseRecord(
        id: 1,
        userId: 1,
        ref: "Fixture 1:1",
        text: "Alpha bravo charlie.",
        translation: "SYN",
        nextTest: "2026-10-20",
        testInterval: 1,
        repN: 1,
        efactor: 2,
        status: "Learning",
        feedback: true,
        mnemonic: "",
        attempts: 0,
        lastTested: "2026-10-20"
    )
}
