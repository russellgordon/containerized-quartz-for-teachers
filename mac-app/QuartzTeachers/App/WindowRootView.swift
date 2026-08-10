import AppKit
import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// The app restores its windows itself. At launch there is exactly one
/// window (system restoration is disabled); it takes the first remembered
/// entry — folder and position — and opens a window for each remaining
/// entry, which carry their own folder and position in their presented
/// value. Deterministic, in the order the windows were open.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// The value this window is presented for.
    @Binding var folder: WindowFolder

    @Environment(\.openWindow) var openWindow

    /// This window's own model. Each window has one.
    @State var workspace: WorkspaceModel = WorkspaceModel()

    /// Where this window should place itself once it is on screen.
    @State var pendingFrame: String = ""

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
                    // A spawned window: its value says where and what.
                    workspace.adoptRestoredPath(folder.path)
                    pendingFrame = folder.frame
                } else if let entry = WindowFolderMemory.claimNextEntry() {
                    // The launch window takes the first remembered entry.
                    workspace.adoptRestoredPath(entry.path)
                    folder.path = entry.path
                    folder.frame = entry.frame
                    pendingFrame = entry.frame
                }
            }
            .background(WindowAccessor { window in
                workspace.window = window
                applyPendingFrame(to: window)
                AppLog.interface.info("""
                    window \(windowIdentity, privacy: .public) opened in \
                    "\(workspace.workspaceURL?.path ?? "", privacy: .public)" \
                    at \(NSStringFromRect(window.frame), privacy: .public)
                    """)
                WorkspaceModel.rememberOpenFolders()
            })
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
                // The launch window reopens the rest of the remembered
                // windows, each carrying its folder and position.
                if WorkspaceModel.isRunningTests {
                    return
                }
                guard WindowFolderMemory.beginSpawnCheckOnce() else {
                    return
                }
                try? await Task.sleep(for: .milliseconds(300))
                for entry in WindowFolderMemory.takeUnclaimed() {
                    openWindow(value: WindowFolder(id: UUID(), path: entry.path, frame: entry.frame))
                }
            }
    }

    // MARK: - Functions

    /// Moves the window to its remembered place, once, sanity-checking the
    /// stored rectangle so a corrupt value cannot produce an unusable
    /// window.
    func applyPendingFrame(to window: NSWindow) {
        if pendingFrame.isEmpty {
            return
        }
        let frame: NSRect = NSRectFromString(pendingFrame)
        pendingFrame = ""
        if frame.width < 300 || frame.height < 300 {
            return
        }
        window.setFrame(frame, display: true)
    }
}
