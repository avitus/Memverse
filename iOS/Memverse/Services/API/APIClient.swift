import Foundation

enum APIError: Error, Equatable {
    case unauthorized
    case http(Int)
    case decoding
    case transportAmbiguous
    case transportFailed
    case cancelled
}

struct APIClient {
    var baseURL: URL
    var session: URLSession
    var accessToken: () async -> String?
    var refresh: () async throws -> Void

    func get<T: Decodable>(_ path: String, query: [String: String] = [:], as type: T.Type) async throws -> T {
        try await send(url: endpoint(path, query: query), method: "GET", body: nil, as: type, allowRefresh: true)
    }

    func put<T: Decodable>(_ path: String, query: [String: String], as type: T.Type) async throws -> T {
        try await send(url: endpoint(path, query: query), method: "PUT", body: nil, as: type, allowRefresh: true)
    }

    func postForm(_ path: String, form: [String: String], authenticated: Bool) async throws -> Data {
        var request = URLRequest(url: endpoint(path))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = OAuthEndpoints.formURLEncoded(form)
        if authenticated, let token = await accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.transportFailed }
        guard (200...299).contains(http.statusCode) else {
            throw http.statusCode == 401 ? APIError.unauthorized : APIError.http(http.statusCode)
        }
        return data
    }

    private func send<T: Decodable>(url: URL, method: String, body: Data?, as type: T.Type, allowRefresh: Bool) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        if let token = await accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.transportFailed }
            if http.statusCode == 401 {
                if allowRefresh {
                    try await refresh()
                    return try await send(url: url, method: method, body: body, as: type, allowRefresh: false)
                }
                throw APIError.unauthorized
            }
            guard (200...299).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding
            }
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            throw Self.classify(error)
        }
    }

    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw Self.classify(error)
        }
    }

    private func endpoint(_ path: String, query: [String: String] = [:]) -> URL {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let segments = trimmed.split(separator: "/").map(String.init)
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }
        components.path = "/" + segments.joined(separator: "/")
        if query.isEmpty == false {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        }
        return components.url ?? baseURL
    }

    static func classify(_ error: URLError) -> APIError {
        switch error.code {
        case .cancelled:
            return .cancelled
        case .timedOut, .networkConnectionLost:
            return .transportAmbiguous
        default:
            return .transportFailed
        }
    }
}
