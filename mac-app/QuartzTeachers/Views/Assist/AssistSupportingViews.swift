import SwiftUI

/// What the assistant tells a teacher it is good at.
///
/// These eleven are not decoration. They are measured — the routing suite
/// probes them word for word — and several of them are matched in code rather
/// than routed, precisely so that what the window promises is what the window
/// delivers. A card offering something the assistant is unreliable at is
/// worse than a card with nothing on it.
struct AssistPromiseCardView: View {

    // MARK: - Stored properties

    /// Called with the phrasing the teacher chose, verbatim.
    let choose: (String) -> Void

    // MARK: - Computed properties

    /// Grouped the way a teacher thinks about them, not the way the tools are
    /// organised.
    private var groups: [(String, [String])] {
        return [
            ("Showing work to students", [
                "Publish Unit 2, Day 3, and everything it links to",
                "Publish tomorrow's class",
                "What would publishing Unit 3, Day 1 change?",
            ]),
            ("Taking it back", [
                "Unpublish Unit 2, Day 3",
                "I published Unit 4, Day 1 by mistake — unpublish it",
                "Undo that",
            ]),
            ("Checking", [
                "What would students see in this section right now?",
                "Rebuild the preview",
            ]),
            ("Putting the site online", [
                "Deploy this section now",
                "Deploy tomorrow's class at 6:30 AM",
                "Cancel that scheduled deploy",
            ]),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Things you can ask for")
                .font(.headline)
            Text("Type your own words if you prefer — these are just the ones it is surest about.")
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(groups, id: \.0) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    ForEach(group.1, id: \.self) { phrasing in
                        Button {
                            choose(phrasing)
                        } label: {
                            Text(phrasing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.10),
                                            in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The one-off download, before it starts.
struct AssistDownloadView: View {

    // MARK: - Stored properties

    let tier: AssistModelTier
    let store: AssistModelStore
    let begin: () -> Void

    // MARK: - Computed properties

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text("The assistant needs a one-time download")
                .font(.headline)

            // Said plainly and up front. A teacher on a school connection or a
            // metered tether deserves to know the size before it starts, not
            // to discover it from a progress bar.
            Text("""
                 It runs entirely on this Mac — nothing you write is sent anywhere. \
                 Plantoir picked \(tier.displayName) to suit this Mac's memory: a \
                 \(tier.downloadDescription) download, kept for next time.
                 """)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Download \(tier.downloadDescription)", action: begin)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("assistDownloadButton")

            if case .failed(let reason) = store.state {
                Text(reason)
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The download, while it runs.
struct AssistDownloadProgressView: View {

    // MARK: - Stored properties

    let fractionComplete: Double
    let receivedBytes: Int64
    let totalBytes: Int64
    let cancel: () -> Void

    // MARK: - Computed properties

    private var received: String {
        return AssistDownloadProgressView.formatter.string(fromByteCount: receivedBytes)
    }

    private var total: String {
        return AssistDownloadProgressView.formatter.string(fromByteCount: totalBytes)
    }

    private static let formatter: ByteCountFormatter = {
        let formatter: ByteCountFormatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: fractionComplete)
                .frame(maxWidth: 320)
            Text("\(received) of \(total)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text("You can carry on working; this window will be ready when it finishes.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Stop", action: cancel)
                .accessibilityIdentifier("assistCancelDownloadButton")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
