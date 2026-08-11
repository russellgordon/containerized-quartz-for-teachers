import SwiftUI

@main
struct QuartzTeachersApp: App {

    // MARK: - Stored properties

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Used to open the About window from the application menu.
    @Environment(\.openWindow) var openWindow

    // MARK: - Initializer

    init() {
        // Register bundled fonts so the settings form can preview the
        // site font choices.
        BundledFontList.registerFonts()
    }

    // MARK: - Body

    var body: some Scene {
        // A plain window group. Per-window SwiftUI persistence is not used
        // for the folder at all: @SceneStorage shared one value across the
        // group's windows, and presented values restored the same way —
        // last writer wins, both windows on one folder. The folder comes
        // from the app's own frame-keyed list instead.
        WindowGroup("Plantoir") {
            WindowRootView()
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
        .commands {
            // The standard About item is replaced so it opens the custom
            // panel instead of the stock one.
            CommandGroup(replacing: .appInfo) {
                Button("About Plantoir") {
                    openWindow(id: "about")
                }
            }
            PreviewCommands()
            CommandGroup(after: .newItem) {
                WorkspaceCommands()
            }
        }

        // The About panel itself: traffic lights only, sized to content,
        // and never restored on relaunch.
        Window("About Plantoir", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)
    }
}
