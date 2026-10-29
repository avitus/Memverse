import Foundation

enum OAuthEndpoints {
    static func passwordGrantRequest(baseURL: URL, username: String, password: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("oauth/token"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(MemverseConfiguration.basicAuthorization, forHTTPHeaderField: "Authorization")
        let body: [String: String] = [
            "grant_type": "password",
            "client_id": MemverseConfiguration.oauthClientID,
            "username": username,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func tokenRequest(baseURL: URL, form: [String: String]) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("oauth/token"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(MemverseConfiguration.basicAuthorization, forHTTPHeaderField: "Authorization")
        request.httpBody = formURLEncoded(form)
        return request
    }

    static func revokeRequest(baseURL: URL, token: String, clientID: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("oauth/revoke"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(MemverseConfiguration.basicAuthorization, forHTTPHeaderField: "Authorization")
        request.httpBody = formURLEncoded(["token": token, "client_id": clientID])
        return request
    }

    static func formURLEncoded(_ fields: [String: String]) -> Data {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let body = fields.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.sorted().joined(separator: "&")
        return Data(body.utf8)
    }
}

enum AuthError: Error, Equatable {
    case tokenRejected
}
