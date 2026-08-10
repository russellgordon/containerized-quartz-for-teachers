import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// A teacher may keep two windows open on different folders — last year's
/// courses beside this year's — so the folder belongs to the window, not to
/// the app.
///
/// `@SceneStorage` is the obvious way to remember it and does not work here:
/// two windows of one `WindowGroup` share a value, so whichever wrote last
/// decided what every window restored, and both came back on one folder.
/// `WindowFolderMemory` keeps the app's own ordered list instead.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// This window's own model. Each window has one.
    @State var workspace: WorkspaceModel = WorkspaceModel()

    /// Identifies this window in the log, so two windows can be told apart.
    @State var windowIdentity: String = String(UUID().uuidString.prefix(4))

    // MARK: - Body

    var body: some View {
        MainWindowView()
            .environment(workspace)
            .focusedSceneValue(\.workspace, workspace)
            .onAppear {
                WorkspaceModel.registerWindowModel(workspace)
                // Windows appear in order and take the remembered folders in
                // the same order. A window beyond what was remembered opens
                // where the teacher last was.
                if let remembered = WindowFolderMemory.claimNextFolder() {
                    workspace.adoptRestoredPath(remembered)
                }
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) opened in \
                    "\(workspace.workspaceURL?.path ?? "", privacy: .public)"
                    """)
                WorkspaceModel.rememberOpenFolders()
            }
            .onChange(of: workspace.workspaceURL) {
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) moved to \
                    "\(workspace.workspaceURL?.path ?? "", privacy: .public)"
                    """)
                WorkspaceModel.rememberOpenFolders()
            }
            .onDisappear {
                WorkspaceModel.unregisterWindowModel(workspace)
            }
    }
}
