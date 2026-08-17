import SwiftUI

/// The app's own settings — the ones that belong to the teacher and their
/// Mac rather than to any one course.
///
/// Reached from Plantoir ▸ Settings… (⌘,), which is where every other Mac
/// application keeps them, so nobody has to be told where it is. Deliberately
/// separate from a course's settings, which live in the main window beside the
/// course they describe: mixing "how should this class's site look" with "how
/// much of this Mac may the assistant use" would put two different kinds of
/// answer in one list, and the teacher would have to work out which was which
/// every time they opened it.
///
/// **One pane, and NO `TabView` around it — that is a decision, not an
/// omission.** A `TabView` with a single tab was tried first, on the reasoning
/// that a second pane will come along eventually. macOS titles a settings
/// window after the SELECTED TAB, so the window came up called "Assistant",
/// and a settings window whose title bar says "Assistant" reads as a window
/// about the assistant that a teacher has ended up in by mistake. Without the
/// tab bar the system titles it "Plantoir Settings", which is the sentence
/// they were looking for. Put the `TabView` back the day there is a second
/// pane to put in it, and not before.
///
/// The Cloudflare Account ID in `AppSettings` is the obvious candidate for
/// that second pane and is deliberately not moved here as part of this change
/// — it sits in a course's settings today, where teachers have learned to find
/// it, and moving it is its own decision with its own migration.
struct PlantoirSettingsView: View {

    // MARK: - Computed properties

    var body: some View {
        AssistantSettingsView()
            // Fixed width, the way macOS settings windows are: the panel is a
            // column of sentences, and a resizable one lets the explanations
            // stretch into single lines that are far harder to read.
            .frame(width: 560)
            .accessibilityIdentifier("plantoirSettings")
    }
}
