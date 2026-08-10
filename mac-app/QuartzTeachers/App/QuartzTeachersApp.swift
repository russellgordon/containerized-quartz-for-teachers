import SwiftUI

@main
struct QuartzTeachersApp: App {

    // MARK: - Stored properties

    @State var workspace = WorkspaceModel.shared

    // MARK: - Initializer

    init() {
        // Register bundled fonts so the settings form can preview the
        // site font choices.
        BundledFontList.registerFonts()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup("Containerized Quartz for Teachers") {
            MainWindowView()
                .environment(workspace)
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
            PreviewCommands()
            CommandGroup(after: .newItem) {
                Button("Change Working Folder…") {
                    workspace.isChoosingWorkspace = true
                }
                Button("Reload Courses") {
                    workspace.reloadCourses()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
