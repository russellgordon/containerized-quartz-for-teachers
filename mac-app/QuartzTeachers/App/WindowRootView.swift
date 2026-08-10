import AppKit
import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// macOS owns window restoration. When the system setting keeps windows, it
/// reopens each one with its frame and — usually — its presented value,
/// which carries the folder. A window that comes back without its value
/// finds its folder in `WindowFolderMemory`, matched by frame while the
/// frame settles; order decides only when frames never match. The app
/// spawns nothing: duplicating what macOS already restored is how two
/// windows once became four.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// The value this window is presented for — nil for a fresh window
    /// that has not been given a folder yet.
    @Binding var folder: WindowFolder?

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
                if let presented = folder, !presented.path.isEmpty {
                    // macOS kept the value: the folder came back with the
                    // window, and the remembered list is not consulted.
                    workspace.adoptRestoredPath(presented.path)
                }
            }
            .background(WindowAccessor { window in
                workspace.window = window
                if (folder?.path ?? "").isEmpty {
                    attemptClaim(for: window, attemptsLeft: 7)
                }
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) opened in \
                    "\(workspace.workspaceURL?.path ?? "", privacy: .public)" \
                    at \(NSStringFromRect(window.frame), privacy: .public)
                    """)
                WorkspaceModel.rememberOpenFolders()
            })
            .onChange(of: workspace.workspaceURL) {
                let path: String = workspace.workspaceURL?.path ?? ""
                folder = WindowFolder(id: folder?.id ?? UUID(), path: path, frame: folder?.frame ?? "")
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) moved to \
                    "\(path, privacy: .public)"
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
    func attemptClaim(for window: NSWindow, attemptsLeft: Int) {
        if !(folder?.path ?? "").isEmpty {
            return
        }
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
        folder = WindowFolder(id: UUID(), path: entry.path, frame: entry.frame)
        AppLog.interface.info("""
            window \(windowIdentity, privacy: .public) claimed \
            "\(entry.path, privacy: .public)" — \(detail, privacy: .public)
            """)
    }
}
