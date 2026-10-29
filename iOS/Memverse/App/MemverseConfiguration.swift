import Foundation

enum MemverseConfiguration {
    /// OAuth application already registered for the previous iOS app.
    static let oauthClientID = "05bdf143c1698c333952941082c383c0552dbb8c88f61ce160844fe2fc2b80e0"

    /// Supplied at build time from `ios/Config/OAuthClient.local.xcconfig`, which is not committed.
    static var oauthClientSecret: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "OAuthClientSecret") as? String ?? ""
        return raw.hasPrefix("$(") ? "" : raw
    }

    static var basicAuthorization: String {
        let pair = "\(oauthClientID):\(oauthClientSecret)"
        return "Basic \(Data(pair.utf8).base64EncodedString())"
    }

    /// Debug builds talk to local Rails. Release uses the public site and has
    /// no local HTTP exception.
    static var apiBaseURL: URL {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["MEMVERSE_API_BASE_URL"],
           let url = URL(string: override) {
            return url
        }
        return URL(string: "http://127.0.0.1:3000")!
        #else
        return URL(string: "https://www.memverse.com")!
        #endif
    }
}
