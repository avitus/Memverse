import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        Group {
            switch model.phase {
            case .signedOut, .signingIn, .failed:
                SignInView(model: model)
            case .loading:
                ProgressView("Loading review")
                    .accessibilityIdentifier("loadingReview")
            case .unavailable(let message):
                SessionProblemView(model: model, message: message)
            case .ready:
                ReviewSplitView(model: model)
            }
        }
        .task { await model.start() }
    }
}

struct SessionProblemView: View {
    @Bindable var model: AppModel
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today's review")
                .font(.largeTitle)
            Text(message)
                .font(.body)
                .accessibilityIdentifier("loadError")
            Button("Try again") {
                Task { await model.reload() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retryLoad")
            Button("Sign out") {
                Task { await model.logout() }
            }
            .accessibilityIdentifier("signOutButton")
        }
        .padding(24)
        .frame(maxWidth: 640, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ReviewSplitView: View {
    @Bindable var model: AppModel
    @State private var selection: Int?

    var body: some View {
        NavigationSplitView {
            ReviewQueueView(model: model, selection: $selection)
        } detail: {
            if let record = model.session.first(where: { $0.id == selection }) {
                ReviewSessionView(model: model, record: record)
                    .id(record.id)
            } else if let statusMessage = model.statusMessage, statusMessage.hasPrefix("Saved.") {
                ContentUnavailableView(
                    "Saved",
                    systemImage: "checkmark.circle",
                    description: Text(statusMessage)
                )
                .accessibilityIdentifier("saveStatus")
            } else if model.session.isEmpty {
                ContentUnavailableView(
                    "Nothing due",
                    systemImage: "checkmark.circle",
                    description: Text(model.statusMessage ?? "There is no verse waiting for review today.")
                )
                .accessibilityIdentifier("emptyQueue")
            } else {
                ContentUnavailableView(
                    "Select a verse",
                    systemImage: "text.book.closed",
                    description: Text("Due verses are listed beside this panel on iPad, and above it on iPhone.")
                )
            }
        }
        .onChange(of: model.preferredSelection) { _, newValue in
            if let newValue {
                selection = newValue
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue, model.session.contains(where: { $0.id == newValue }) else { return }
            if newValue != model.preferredSelection {
                model.statusMessage = nil
            }
        }
    }
}
