import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// A teacher may keep two windows open on different folders — last year's
/// courses beside this year's — so the folder belongs to the window, not to
/// the app. `@SceneStorage` is what macOS restores per window.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// This window's folder, restored by macOS when the window comes back.
    @SceneStorage("workspacePath") var restoredWorkspacePath: String = ""

    /// This window's own model. Each window has one.
    @State var workspace: WorkspaceModel = WorkspaceModel()

    /// Identifies this window in the log, so two windows restoring the same
    /// folder can be told from one window logging twice.
    @State var windowIdentity: String = String(UUID().uuidString.prefix(4))

    // MARK: - Body

    var body: some View {
        MainWindowView()
            .environment(workspace)
            .focusedSceneValue(\.workspace, workspace)
            .onAppear {
                WorkspaceModel.registerWindowModel(workspace)
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) appeared —                     scene storage: "\(restoredWorkspacePath, privacy: .public)",                     last-used: "\(workspace.workspaceURL?.path ?? "", privacy: .public)"
                    """)
                // A restored window returns to its own folder; a brand new
                // one starts from the last folder chosen anywhere.
                if restoredWorkspacePath.isEmpty {
                    restoredWorkspacePath = workspace.workspaceURL?.path ?? ""
                } else {
                    workspace.adoptRestoredPath(restoredWorkspacePath)
                }
            }
            .onChange(of: workspace.workspaceURL) {
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) chose                     "\(workspace.workspaceURL?.path ?? "", privacy: .public)" — writing it to scene storage
                    """)
                restoredWorkspacePath = workspace.workspaceURL?.path ?? ""
            }
    }
}
