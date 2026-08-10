import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// The folder rides in the window's presented value (`WindowFolder`), which
/// macOS encodes into restoration state — so a restored window comes back
/// in its own folder, at its own position. When restoration has nothing
/// (the app was rebuilt, killed from Xcode, or windows are closed on quit),
/// the fallback list in `WindowFolderMemory` reopens the windows that were
/// open, in order.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// The value this window is presented for. Writing the folder here is
    /// what places it into the window's restoration state.
    @Binding var folder: WindowFolder

    @Environment(\.openWindow) var openWindow

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
                if !folder.path.isEmpty {
                    // Restored by the system, folder and all.
                    workspace.adoptRestoredPath(folder.path)
                } else if let remembered = WindowFolderMemory.claimNextFolder() {
                    // A blank window at launch takes the next remembered
                    // folder, so the windows come back even when the
                    // system restored nothing.
                    workspace.adoptRestoredPath(remembered)
                    folder.path = remembered
                }
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) opened in \
                    "\(workspace.workspaceURL?.path ?? "", privacy: .public)"
                    """)
                WorkspaceModel.rememberOpenFolders()
            }
            .onChange(of: workspace.workspaceURL) {
                folder.path = workspace.workspaceURL?.path ?? ""
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) moved to \
                    "\(folder.path, privacy: .public)"
                    """)
                WorkspaceModel.rememberOpenFolders()
            }
            .onDisappear {
                WorkspaceModel.unregisterWindowModel(workspace)
            }
            .task {
                // One window per launch checks, once the dust settles,
                // whether any remembered folders still have no window —
                // and opens them. When the system already restored every
                // window, there is nothing left to take and this spawns
                // nothing.
                if WorkspaceModel.isRunningTests {
                    return
                }
                guard WindowFolderMemory.beginSpawnCheckOnce() else {
                    return
                }
                try? await Task.sleep(for: .milliseconds(600))
                for path in WindowFolderMemory.takeUnclaimed() {
                    openWindow(value: WindowFolder(id: UUID(), path: path))
                }
            }
    }
}
