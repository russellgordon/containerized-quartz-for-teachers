import AppKit
import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// macOS restores the windows and their frames; the folders come from the
/// app's own list, keyed by frame. SwiftUI's per-window persistence is
/// deliberately not involved: both `@SceneStorage` and presented values
/// proved to share one value across the group's windows on restore — last
/// writer wins — which put every window on the same folder.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// This window's own model. Each window has one.
    @State var workspace: WorkspaceModel = WorkspaceModel()

    /// This window's claim on the remembered folders.
    @State var claimant: WindowFolderClaimant = WindowFolderClaimant()

    /// Identifies this window in the log, so two windows can be told apart.
    @State var windowIdentity: String = String(UUID().uuidString.prefix(4))

    // MARK: - Body

    var body: some View {
        MainWindowView()
            .environment(workspace)
            .focusedSceneValue(\.workspace, workspace)
            .onAppear {
                WorkspaceModel.registerWindowModel(workspace)
            }
            .background(WindowAccessor { window in
                workspace.window = window
                attemptClaim(for: window, attemptsLeft: 7)
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) opened in \
                    "\(workspace.workspaceURL?.path ?? "", privacy: .public)" \
                    at \(NSStringFromRect(window.frame), privacy: .public)
                    """)
                WorkspaceModel.rememberOpenFolders()
            })
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

    // MARK: - Functions

    /// Finds this window's folder by its frame, retrying briefly because a
    /// reopened window's frame settles a moment after the window exists.
    /// The claimant claims at most once, and claims close shortly after
    /// launch — a window opened mid-session inherits nothing.
    func attemptClaim(for window: NSWindow, attemptsLeft: Int) {
        if let entry = claimant.frameDidSettle(NSStringFromRect(window.frame)) {
            adopt(entry, how: "matched by frame")
            return
        }
        if attemptsLeft <= 0 {
            if let entry = claimant.giveUp() {
                adopt(entry, how: "fell back to order")
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            attemptClaim(for: window, attemptsLeft: attemptsLeft - 1)
        }
    }

    /// Takes a remembered window as this window's own.
    func adopt(_ entry: WindowFolderMemory.Entry, how detail: String) {
        workspace.adoptRestoredPath(entry.path)
        AppLog.interface.info("""
            window \(windowIdentity, privacy: .public) claimed \
            "\(entry.path, privacy: .public)" — \(detail, privacy: .public)
            """)
    }
}
