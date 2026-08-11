import AppKit
import SwiftUI

/// The About panel: the app icon beside the name, version, what the app
/// is, support details, credits, and copyright — replacing the stock
/// About box.
///
/// Every size below is a `@ScaledMetric`, so the whole panel — artwork,
/// type, and width together — grows with the system's Accessibility ▸
/// Display ▸ Text size, instead of leaving someone who enlarges text
/// with the same small panel they had before.
struct AboutView: View {

    // MARK: - Stored properties

    /// Where teachers go for help.
    let supportURL: URL = URL(string: "https://github.com/russellgordon/containerized-quartz-for-teachers")!

    /// Where teachers write in for help. nil until a real address exists —
    /// the row and its spacing disappear rather than advertise a dead inbox.
    let supportEmailAddress: String? = nil

    /// Shown at the very bottom. Set to nil to omit the line.
    let copyrightNotice: String? = "Copyright 2026 Russell Gordon"

    /// What the app is, in one line.
    let tagline: String = "Turns a folder of Markdown notes into a fast, searchable class website you own."

    /// Where the name comes from — and what the app promises to do.
    let namesake: String = "A plantoir is a dibber — the simple hand tool that opens a hole at the right depth so a seedling can be set in and take root. This one does the same for teaching materials. Write in Obsidian, preview locally, publish when you’re ready."

    /// The credit lines, shown smallest, at the bottom above the copyright.
    let credits: [LocalizedStringKey] = [
        "Built on [Quartz](https://quartz.jzhao.xyz) by Jacky Zhao.",
        "Designed by Russell Gordon.",
        "Built with Claude.",
        "MIT licensed — use, remix, and share freely, especially with other educators.",
    ]

    // The measurements, at the SYSTEM text size. Scaling from these keeps
    // the panel's proportions as the text grows.
    @ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 128
    @ScaledMetric(relativeTo: .body) var nameSize: CGFloat = 26
    @ScaledMetric(relativeTo: .body) var versionSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) var bodySize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) var creditsSize: CGFloat = 11
    @ScaledMetric(relativeTo: .body) var panelWidth: CGFloat = 540
    @ScaledMetric(relativeTo: .body) var outerPadding: CGFloat = 24
    @ScaledMetric(relativeTo: .body) var columnSpacing: CGFloat = 24

    // MARK: - Computed properties

    /// The application name, read from the bundle so it follows a rename.
    var applicationName: String {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        return displayName ?? bundleName ?? "Plantoir"
    }

    /// Marketing version and build number, formatted as "Version 1.0 (1)".
    ///
    /// Info.plist must reference `$(MARKETING_VERSION)` and
    /// `$(CURRENT_PROJECT_VERSION)` rather than hardcoded literals, or this
    /// will not update when the build settings change.
    var versionSummary: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(shortVersion) (\(buildNumber))"
    }

    /// A mailto link built from the support address, when there is one.
    var supportEmailURL: URL? {
        guard let supportEmailAddress else {
            return nil
        }
        return URL(string: "mailto:\(supportEmailAddress)")
    }

    var body: some View {
        HStack(alignment: .top, spacing: columnSpacing) {

            icon

            VStack(alignment: .leading, spacing: 0) {

                Text(applicationName)
                    .font(.system(size: nameSize, weight: .bold))

                Text(versionSummary)
                    .font(.system(size: versionSize))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                Text(tagline)
                    .font(.system(size: bodySize))
                    .padding(.top, 14)

                Text(namesake)
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                contactDetails
                    .padding(.top, 18)

                creditLines
                    .padding(.top, 18)

                if let copyrightNotice {
                    Text(copyrightNotice)
                        .font(.system(size: creditsSize))
                        .foregroundStyle(.secondary)
                        .padding(.top, 14)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(outerPadding)
        .frame(width: panelWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The application icon itself — the compiled artwork macOS shows in
    /// the Dock, so the About panel can never drift from the real icon and
    /// no separate flattened asset is needed. It arrives already shaped
    /// with its margins, so no clipping is applied here.
    var icon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: iconSize, height: iconSize)
            .accessibilityLabel("\(applicationName) icon")
    }

    /// Label and value rows for support details, the values left-aligned
    /// to a common edge.
    var contactDetails: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {

            GridRow {
                Text("Support")
                    .font(.system(size: bodySize))
                    .foregroundStyle(.secondary)
                Link(destination: supportURL) {
                    Text(supportURL.absoluteString)
                        .font(.system(size: bodySize, weight: .semibold))
                }
            }

            if let supportEmailAddress, let supportEmailURL {
                GridRow {
                    Text("Email")
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                    Link(destination: supportEmailURL) {
                        Text(supportEmailAddress)
                            .font(.system(size: bodySize, weight: .semibold))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    /// Who and what the app is built on, one quiet line each.
    var creditLines: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(credits.indices), id: \.self) { index in
                Text(credits[index])
                    .font(.system(size: creditsSize))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.accentColor)
    }
}

// MARK: - Preview

#Preview {
    AboutView()
}
