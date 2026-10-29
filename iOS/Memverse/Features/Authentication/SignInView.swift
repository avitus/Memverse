import SwiftUI

struct SignInView: View {
    @Bindable var model: AppModel
    @State private var email = ""
    @State private var password = ""

    private var isSigningIn: Bool {
        if case .signingIn = model.phase { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Memverse")
                .font(.largeTitle)
            Text("Sign in with the email and password for your existing account. Today's due verses stay on the server, and the grade you choose is the grade that is saved.")
                .font(.body)
                .foregroundStyle(.secondary)
            TextField("Email", text: $email)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("emailField")
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("passwordField")
            if case .failed(let message) = model.phase {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .accessibilityHidden(true)
                    Text(message)
                        .font(.body)
                        .accessibilityIdentifier("signInError")
                }
            }
            if isSigningIn {
                ProgressView("Signing in")
                    .accessibilityIdentifier("signingIn")
            }
            Button("Sign in") {
                Task { await model.signIn(email: email, password: password) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSigningIn || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
            .accessibilityIdentifier("signInButton")
            #if DEBUG
            Text("Debug server \(MemverseConfiguration.apiBaseURL.absoluteString)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("debugServer")
            #endif
        }
        .padding(24)
        .frame(maxWidth: 640, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
