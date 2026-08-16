import SwiftUI

@main
struct QuartzTeachersApp: App {

    // MARK: - Stored properties

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Used to open the About window from the application menu.
    @Environment(\.openWindow) var openWindow

    // MARK: - Initializer

    init() {
        // Claude Code drives the same tools the built-in assistant does, by
        // launching this binary with --mcp-stdio. Checked FIRST, and it never
        // returns: a server must not put a window on screen, register fonts,
        // or touch the teacher's saved window state.
        //
        // Serving from the app rather than a separate executable is what stops
        // the two clients' tool surfaces drifting — and it cannot be left out
        // of a build by a packaging script, the way Windows' plantoir-mcp.exe
        // was, because it IS the app.
        if let folder = AssistMCPServer.requestedWorkingFolder(from: CommandLine.arguments) {
            AssistMCPServer.serve(workingFolder: folder)
        }

        // Writing the contract in `contracts/` is the other thing this binary
        // does without becoming an app. Same reasoning as the MCP server: the
        // files describe what the app SAYS and which tools it has, so they are
        // written by the app rather than by a script that would have to be
        // kept in step with it by hand.
        if let directory = AssistContract.requestedDirectory(from: CommandLine.arguments) {
            print(AssistContract.write(into: directory))
            exit(0)
        }

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

        // The assistant, one window per section.
        //
        // Keyed by the section rather than opened as a plain window, so asking
        // for it twice brings the existing one forward. A second window for
        // the same section would start a second engine — several more
        // gigabytes of the teacher's memory — and give them two conversations
        // that each believe they are the only one changing anything.
        //
        // Not restored on relaunch: reopening would load a model before the
        // teacher had asked for one.
        WindowGroup("Assistant", id: "assistant", for: AssistWindowRequest.self) { $request in
            if let request {
                AssistWindowView(
                    courseCode: request.courseCode,
                    sectionNumber: request.sectionNumber,
                    workingFolder: request.workingFolder
                )
            }
        }
        .restorationBehavior(.disabled)

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
