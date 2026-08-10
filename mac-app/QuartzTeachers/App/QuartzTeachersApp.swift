import SwiftUI

@main
struct QuartzTeachersApp: App {

    // MARK: - Stored properties

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Initializer

    init() {
        // Register bundled fonts so the settings form can preview the
        // site font choices.
        BundledFontList.registerFonts()
    }

    // MARK: - Body

    var body: some Scene {
        // Value-presented windows: each window is FOR its folder. The value
        // stays OPTIONAL — nil meaning a fresh window — because supplying a
        // defaultValue makes SwiftUI force-unwrap the presented value, and
        // the launch window arrives with nil: an immediate crash
        // (BindingOperations.ForceUnwrapping in PresentedWindowContent).
        WindowGroup("Containerized Quartz for Teachers", for: WindowFolder.self) { $folder in
            WindowRootView(folder: $folder)
                // A bounded IDEAL size matters as much as the minimum:
                // without it the window's content is sized by whatever
                // its descendants claim, and one overgrown view drags
                // the whole interface (sidebar included) out of view.
                .frame(
                    minWidth: 900,
                    idealWidth: 1100,
                    maxWidth: .infinity,
                    minHeight: 600,
                    idealHeight: 720,
                    maxHeight: .infinity
                )
        }
        // The app restores its own windows — count, folder, and position —
        // from the list it keeps. System restoration overlapping with that
        // produced spare windows and shuffled folders, so it is off.
        .restorationBehavior(.disabled)
        .commands {
            PreviewCommands()
            CommandGroup(after: .newItem) {
                WorkspaceCommands()
            }
        }
    }
}
