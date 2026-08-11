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

    /// This window's own model. Each window has one. A mid-session window
    /// arrives already knowing its folder, so the picker never flashes.
    @State var workspace: WorkspaceModel = WorkspaceModel.modelForNewWindow()

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
                if workspace.window?.isKeyWindow == true, let path = workspace.workspaceURL?.path {
                    WorkspaceModel.mostRecentKeyFolderPath = path
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
                // Remember where the teacher is working, so the NEXT new
                // window can open there. A window with no folder yet (this
                // one, freshly opened) must not erase the memory.
                guard (notification.object as? NSWindow) === workspace.window else {
                    return
                }
                if let path = workspace.workspaceURL?.path {
                    WorkspaceModel.mostRecentKeyFolderPath = path
                }
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
        // Once the claims have closed there is nothing to keep retrying
        // for — this is a mid-session window, and it should get its folder
        // (or its picker) right away rather than a second later.
        let claimsHaveClosed: Bool = Date() > WindowFolderMemory.claimsOpenUntil
        if attemptsLeft <= 0 || claimsHaveClosed {
            if let entry = claimant.giveUp() {
                adopt(entry, how: "fell back to order")
            } else {
                inheritFromOpenWindows()
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            attemptClaim(for: window, attemptsLeft: attemptsLeft - 1)
        }
    }

    /// A brand-new window with nothing to restore: open in the folder of
    /// the window that was key when it was created — or, as the only
    /// window, stay empty so the picker shows.
    func inheritFromOpenWindows() {
        guard workspace.workspaceURL == nil else {
            return
        }
        var otherOpenFolderPaths: [String] = []
        for model in WorkspaceModel.windowModels {
            if model !== workspace, let path = model.workspaceURL?.path {
                otherOpenFolderPaths.append(path)
            }
        }
        guard let path = WorkspaceModel.folderForNewWindow(
            otherOpenFolderPaths: otherOpenFolderPaths,
            mostRecentKeyPath: WorkspaceModel.mostRecentKeyFolderPath
        ) else {
            AppLog.interface.info("window \(windowIdentity, privacy: .public) is the only window — opening without a folder")
            return
        }
        workspace.adoptRestoredPath(path)
        AppLog.interface.info("""
            window \(windowIdentity, privacy: .public) inherited \
            "\(path, privacy: .public)" from the key window
            """)
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
