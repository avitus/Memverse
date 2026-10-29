import SwiftUI

struct ReviewSessionView: View {
    @Bindable var model: AppModel
    let record: MemverseRecord
    @State private var guess = ""
    @State private var showVerse = false
    @FocusState private var guessFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(record.ref)
                    .font(.largeTitle)
                    .accessibilityIdentifier("reviewReference")
                Text(record.translation)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("reviewTranslation")

                if record.showsMnemonic {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("First letters")
                            .font(.headline)
                        Text(record.mnemonic)
                            .font(.title3.monospaced())
                            .accessibilityIdentifier("mnemonicHint")
                            .accessibilityLabel("First-letter hint")
                            .accessibilityValue(record.mnemonic)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                }

                TextField("Type the verse", text: $guess, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .lineLimit(3...8)
                    .focused($guessFocused)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("verseGuess")

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: comparisonSymbol)
                        .accessibilityHidden(true)
                    Text(comparison.feedback)
                        .font(.body)
                        .accessibilityIdentifier("feedback")
                        .accessibilityLabel(comparisonLabel)
                }

                Button(showVerse ? "Hide verse" : "Show verse") {
                    showVerse.toggle()
                }
                .accessibilityIdentifier("showVerse")

                if showVerse {
                    Text(record.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("revealedVerse")
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("How well did you remember it?")
                        .font(.headline)
                    ForEach(ReviewGrade.allCases) { grade in
                        Button {
                            Task { _ = await model.submit(record, grade: grade) }
                        } label: {
                            Text("\(grade.rawValue). \(grade.title)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isSubmitting)
                        .accessibilityIdentifier("grade-\(grade.rawValue)")
                    }
                }

                if model.isSubmitting {
                    ProgressView("Saving")
                        .accessibilityIdentifier("saving")
                }

                if let statusMessage = model.statusMessage {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: statusMessage.hasPrefix("Saved.") ? "checkmark.circle" : "exclamationmark.circle")
                            .accessibilityHidden(true)
                        Text(statusMessage)
                            .font(.body)
                            .accessibilityIdentifier("saveStatus")
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-uiTestingQueue") { return }
            #endif
            guessFocused = true
        }
    }

    private var comparisonSymbol: String {
        if comparison.waiting { return "ellipsis.circle" }
        if comparison.correct { return "checkmark.circle" }
        return "circle"
    }

    private var comparisonLabel: String {
        if comparison.waiting { return "Waiting for you to begin typing" }
        if comparison.correct { return "Correct" }
        return "Not a complete match"
    }

    private var comparison: VerseComparison.Result {
        VerseComparison.compare(
            expected: record.text,
            guess: guess,
            feedbackEnabled: record.feedback,
            allowFirstLetter: record.allowsFirstLetter
        )
    }
}
