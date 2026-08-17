import SwiftUI

/// Asks for a publishing credential the way a person would explain it:
/// what it is for, where to get it, and a field to paste it into.
///
/// It replaces a one-line alert that said "Paste Netlify token:" and
/// nothing else. The page that makes the token is offered as a LINK the
/// teacher clicks when they are ready — the launchers used to open it
/// themselves, and a browser tab appearing unasked reads as a fault.
struct CredentialRequestSheet: View {

    // MARK: - Stored properties

    let request: CredentialRequest

    /// What to do with the finished answer, and with a change of mind.
    let onSend: (String) -> Void
    let onCancel: () -> Void

    @State var answer: String = ""

    // MARK: - Computed properties

    /// Whitespace either side of a pasted code is invisible and breaks the
    /// sign-in, so it never reaches the launcher.
    var tidiedAnswer: String {
        return answer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(request.title)
                .font(.title2.bold())

            Text(request.explanation)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(request.steps.enumerated()), id: \.offset) { pair in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(pair.offset + 1).")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(pair.element)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Link(destination: request.linkAddress) {
                Label(request.linkTitle, systemImage: "safari")
            }
            .accessibilityIdentifier("credentialLink")

            VStack(alignment: .leading, spacing: 4) {
                Text(request.fieldLabel)
                    .font(.callout)
                // The label above the field says what it is; the field's
                // own placeholder says what to do, rather than repeating
                // the label back.
                if request.isSecret {
                    SecureField("Paste it here", text: $answer)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .accessibilityIdentifier("credentialField")
                        .onSubmit {
                            sendAnswer()
                        }
                } else {
                    TextField("Paste it here", text: $answer)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .accessibilityIdentifier("credentialField")
                        .onSubmit {
                            sendAnswer()
                        }
                }
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
                    sendAnswer()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(tidiedAnswer.isEmpty)
                .accessibilityIdentifier("credentialSendButton")
            }
        }
        .padding(20)
        .frame(width: 460)
        .accessibilityIdentifier("credentialSheet")
    }

    // MARK: - Functions

    func sendAnswer() {
        if tidiedAnswer.isEmpty {
            return
        }
        onSend(tidiedAnswer)
        answer = ""
    }
}
