import SwiftUI

/// What the assistant tells a teacher it is good at — kept on screen for
/// the whole conversation, not just at the start.
///
/// These eleven are not decoration. They are measured — the routing suite
/// probes them word for word — and several are matched in code rather than
/// routed, precisely so that what the window promises is what the window
/// delivers. A card offering something the assistant is unreliable at is
/// worse than a card with nothing on it.
///
/// **Why it stays, and why it folds.** It used to appear only while the
/// conversation was empty, which meant the teacher saw the list once, at the
/// moment they knew least about what to do with it, and never again. But a
/// list this long sitting open would push the conversation off the screen it
/// belongs on. So each kind of request is a disclosure group, shut by
/// default: four short lines a teacher can scan, and open when they want
/// reminding.
struct AssistPromptShelfView: View {

    // MARK: - Stored properties

    /// Called with the phrasing the teacher chose, verbatim — the wording
    /// matters, so nothing paraphrases it on the way through.
    let choose: (String) -> Void

    /// Which groups are open, remembered across windows and launches.
    ///
    /// `@AppStorage` rather than `@SceneStorage` on purpose. Scene storage is
    /// per-window: it would restore this window's shape when THIS window came
    /// back, but opening the assistant on a different section is a different
    /// scene, so a teacher who had opened "Taking it back" would find it shut
    /// again. This is a preference about how they like the shelf, not a fact
    /// about one window — and the app already has a note about scene storage
    /// sharing one value across a window group and losing to the last writer.
    ///
    /// Stored as one string because `@AppStorage` holds no sets. Group titles
    /// contain no `|`, so it is a safe separator; a title that ever does will
    /// simply be forgotten rather than corrupting the rest.
    @AppStorage("AssistPromptShelfOpenGroups") private var openGroupsRaw: String = ""

    /// How tall the groups actually are, measured.
    @State private var contentHeight: CGFloat = 0

    /// The most the shelf may take. Past this it scrolls, so a teacher who
    /// opens every group gives up their own scroll position rather than the
    /// conversation.
    private static let mostHeight: CGFloat = 240

    // MARK: - Computed properties

    /// The open groups, read back from the stored string.
    private var expanded: Set<String> {
        var titles: Set<String> = []
        for piece in openGroupsRaw.split(separator: "|") {
            let title: String = String(piece)
            if !title.isEmpty {
                titles.insert(title)
            }
        }
        return titles
    }

    // MARK: - Computed properties

    /// Grouped the way a teacher thinks about them, not the way the tools
    /// are organised.
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
        VStack(alignment: .leading, spacing: 2) {
            Text("Things you can ask for")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Hugs its content when shut, caps and scrolls when open.
            //
            // A ScrollView takes every point it is offered, so on its own it
            // reserved the full cap even with all four groups closed — a
            // stripe of empty space between the shelf and the conversation.
            // Measuring the content and asking for the SMALLER of the two is
            // what makes four closed lines occupy four lines.
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(groups, id: \.0) { group in
                        DisclosureGroup(isExpanded: binding(for: group.0)) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(group.1, id: \.self) { phrasing in
                                    Button {
                                        choose(phrasing)
                                    } label: {
                                        Text(phrasing)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.secondary.opacity(0.10),
                                                        in: RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("assistSuggestion-\(phrasing)")
                                }
                            }
                            .padding(.top, 4)
                            .padding(.leading, 2)
                        } label: {
                            Text(group.0)
                                .font(.callout)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    }
                }
                .padding(.bottom, 8)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: AssistShelfHeightKey.self, value: proxy.size.height
                        )
                    }
                )
            }
            .frame(height: min(contentHeight, AssistPromptShelfView.mostHeight))
            .onPreferenceChange(AssistShelfHeightKey.self) { measured in
                contentHeight = measured
            }
        }
        .background(.bar)
    }

    // MARK: - Functions

    /// One group's open/shut state, as a binding a `DisclosureGroup` can
    /// drive, written straight back to the stored preference.
    private func binding(for title: String) -> Binding<Bool> {
        return Binding(
            get: {
                return expanded.contains(title)
            },
            set: { isOpen in
                var titles: Set<String> = expanded
                if isOpen {
                    titles.insert(title)
                } else {
                    titles.remove(title)
                }
                // Sorted so the stored value does not churn between launches
                // just because a Set enumerated differently.
                var ordered: [String] = []
                for stored in titles {
                    ordered.append(stored)
                }
                ordered.sort()
                openGroupsRaw = ordered.joined(separator: "|")
            }
        )
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

/// Carries the shelf's measured height out of its content.
private struct AssistShelfHeightKey: PreferenceKey {

    // MARK: - Stored properties

    static let defaultValue: CGFloat = 0

    // MARK: - Functions

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
