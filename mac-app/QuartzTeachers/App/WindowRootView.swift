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

    // MARK: - Body

    var body: some View {
        MainWindowView()
            .environment(workspace)
            .focusedSceneValue(\.workspace, workspace)
            .onAppear {
                WorkspaceModel.registerWindowModel(workspace)
                // A restored window returns to its own folder; a brand new
                // one starts from the last folder chosen anywhere.
                if restoredWorkspacePath.isEmpty {
                    restoredWorkspacePath = workspace.workspaceURL?.path ?? ""
                } else {
                    workspace.adoptRestoredPath(restoredWorkspacePath)
                }
            }
            .onChange(of: workspace.workspaceURL) {
                restoredWorkspacePath = workspace.workspaceURL?.path ?? ""
            }
    }
}
