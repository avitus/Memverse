import Foundation

struct AuthService {
    var baseURL: URL
    var clientID: String
    var session: URLSession
    var store: TokenStoring

    func signIn(email: String, password: String) async throws {
        let tokens = try await exchange(request: OAuthEndpoints.passwordGrantRequest(
            baseURL: baseURL,
            username: email,
            password: password
        ))
        try store.save(tokens)
    }

    func refreshIfNeeded() async throws {
        guard let current = try store.load() else { throw APIError.unauthorized }
        if current.isExpired == false { return }
        try await refresh(current)
    }

    func forceRefresh() async throws {
        guard let current = try store.load() else { throw APIError.unauthorized }
        try await refresh(current)
    }

    func logout() async throws {
        guard let current = try store.load() else { return }
        var request = OAuthEndpoints.revokeRequest(baseURL: baseURL, token: current.accessToken, clientID: clientID)
        request.timeoutInterval = 30
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.http((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        try store.clear()
    }

    func accessToken() async -> String? {
        try? store.load()?.accessToken
    }

    private func refresh(_ current: TokenSet) async throws {
        guard let refreshToken = current.refreshToken else { throw APIError.unauthorized }
        let tokens = try await exchange(form: [
            "grant_type": "refresh_token",
            "client_id": clientID,
            "refresh_token": refreshToken
        ])
        try store.save(tokens)
    }

    private func exchange(form: [String: String]) async throws -> TokenSet {
        try await exchange(request: OAuthEndpoints.tokenRequest(baseURL: baseURL, form: form))
    }

    private func exchange(request: URLRequest) async throws -> TokenSet {
        var request = request
        request.timeoutInterval = 30
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw APIClient.classify(error)
        }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AuthError.tokenRejected
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        let expiresAt = decoded.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        return TokenSet(accessToken: decoded.accessToken, refreshToken: decoded.refreshToken, expiresAt: expiresAt)
    }
}

private struct TokenResponse: Decodable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
