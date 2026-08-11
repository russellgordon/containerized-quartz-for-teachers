import AppKit
import SwiftUI

/// The About panel: the app icon at full size beside the name, version,
/// support details, and copyright — replacing the stock About box.
struct AboutView: View {

    // MARK: - Stored properties

    /// Where teachers go for help.
    let supportURL: URL = URL(string: "https://github.com/russellgordon/containerized-quartz-for-teachers")!

    /// Where teachers write in for help. nil until a real address exists —
    /// the row and its spacing disappear rather than advertise a dead inbox.
    let supportEmailAddress: String? = nil

    /// Shown beneath the support details. Set to nil to omit the line.
    let copyrightNotice: String? = "Copyright 2026 Russell Gordon"

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
        HStack(alignment: .top, spacing: 28) {

            icon

            VStack(alignment: .leading, spacing: 0) {

                Text(applicationName)
                    .font(.system(size: 38, weight: .bold))

                Text(versionSummary)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                contactDetails
                    .padding(.top, 32)

                if let copyrightNotice {
                    Text(copyrightNotice)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 32)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(28)
        .frame(width: 620, alignment: .leading)
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
            .frame(width: 200, height: 200)
            .accessibilityLabel("\(applicationName) icon")
    }

    /// Label and value rows for support details, the values left-aligned
    /// to a common edge.
    var contactDetails: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 20, verticalSpacing: 12) {

            GridRow {
                Text("Support")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Link(destination: supportURL) {
                    Text(supportURL.absoluteString)
                        .font(.system(size: 15, weight: .semibold))
                }
            }

            if let supportEmailAddress, let supportEmailURL {
                GridRow {
                    Text("Email")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Link(destination: supportEmailURL) {
                        Text(supportEmailAddress)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }
}

// MARK: - Preview

#Preview {
    AboutView()
}
