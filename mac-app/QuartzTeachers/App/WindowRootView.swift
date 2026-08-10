import AppKit
import SwiftUI

/// One window's worth of app: its own working folder, remembered separately
/// from every other window's.
///
/// Windows can arrive two ways at launch: reopened by macOS (when the
/// system setting keeps windows), which restores their frames but not
/// their values and in an order of its own choosing — or spawned by the
/// app for any remembered window macOS did not bring back. A reopened
/// window finds its folder by matching its own frame against the
/// remembered list; matching by order is what swapped folders between
/// windows.
struct WindowRootView: View {

    // MARK: - Stored properties

    /// The value this window is presented for — nil for a fresh window
    /// that has not been given a folder yet.
    @Binding var folder: WindowFolder?

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
                if let presented = folder, !presented.path.isEmpty {
                    // A spawned window: its value says where and what.
                    workspace.adoptRestoredPath(presented.path)
                    pendingFrame = presented.frame
                }
            }
            .background(WindowAccessor { window in
                workspace.window = window
                applyPendingFrame(to: window)
                if (folder?.path ?? "").isEmpty {
                    claimFolder(for: window, attemptsLeft: 7)
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
            .task {
                // One pass, after the reopened windows have claimed their
                // folders: any remembered window still unclaimed did not
                // come back, so open it — folder and frame in its value.
                if WorkspaceModel.isRunningTests {
                    return
                }
                guard WindowFolderMemory.beginSpawnCheckOnce() else {
                    return
                }
                try? await Task.sleep(for: .milliseconds(2000))
                for entry in WindowFolderMemory.takeUnclaimed() {
                    openWindow(value: WindowFolder(id: UUID(), path: entry.path, frame: entry.frame))
                }
            }
    }

    // MARK: - Functions

    /// Finds this window's folder by its frame, retrying briefly because a
    /// reopened window's frame settles a moment after the window exists.
    /// Only when the frame never matches does order decide — the case
    /// where there were no frames to restore at all.
    func claimFolder(for window: NSWindow, attemptsLeft: Int) {
        if !WindowFolderMemory.hasEntriesToClaim() {
            return
        }
        if !(folder?.path ?? "").isEmpty {
            return
        }
        let frame: String = NSStringFromRect(window.frame)
        if let entry = WindowFolderMemory.claimEntry(matchingFrame: frame) {
            adopt(entry, log: "matched by frame")
            return
        }
        if attemptsLeft <= 0 {
            if let entry = WindowFolderMemory.claimNextEntry() {
                adopt(entry, log: "fell back to order")
                pendingFrame = entry.frame
                applyPendingFrame(to: window)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            claimFolder(for: window, attemptsLeft: attemptsLeft - 1)
        }
    }

    /// Takes a remembered window as this window's own.
    func adopt(_ entry: WindowFolderMemory.Entry, log detail: String) {
        workspace.adoptRestoredPath(entry.path)
        folder = WindowFolder(id: UUID(), path: entry.path, frame: entry.frame)
        AppLog.interface.info("""
            window \(windowIdentity, privacy: .public) claimed \
            "\(entry.path, privacy: .public)" — \(detail, privacy: .public)
            """)
    }

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
