import SwiftUI

struct ReviewQueueView: View {
    @Bindable var model: AppModel
    @Binding var selection: Int?
    @State private var confirmSignOut = false

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(model.session) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.ref)
                            .font(.headline)
                        Text(record.translation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Due \(record.nextTest)")
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("due-\(record.id)")
                    .tag(record.id)
                }
            } header: {
                Text(model.session.isEmpty ? "Today" : "\(model.session.count) due today")
                    .accessibilityIdentifier("dueCount")
            }
        }
        .navigationTitle(model.profile?.name.map { "Review, \($0)" } ?? "Review")
        .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        .overlay {
            if model.session.isEmpty {
                ContentUnavailableView(
                    "Nothing due",
                    systemImage: "checkmark.circle",
                    description: Text(model.statusMessage ?? "There is no verse waiting for review today.")
                )
                .accessibilityIdentifier("emptyQueue")
            }
        }
        .toolbar {
            Button("Sign out") {
                confirmSignOut = true
            }
            .accessibilityIdentifier("signOutButton")
        }
        .confirmationDialog("Sign out of Memverse?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                Task { await model.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your saved grades stay on the server.")
        }
        .refreshable { await model.reload() }
    }
}
