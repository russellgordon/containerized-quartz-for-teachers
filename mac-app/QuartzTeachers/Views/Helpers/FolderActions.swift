import AppKit
import Foundation

/// Folder-related actions offered by sidebar context menus.
enum FolderActions {

    // MARK: - Functions

    /// Opens a Finder window showing the contents of the folder.
    static func showInFinder(_ folderURL: URL) {
        NSWorkspace.shared.open(folderURL)
    }

    /// Opens a new Terminal window whose working directory is the folder
    /// (the same behaviour as dropping the folder onto Terminal's icon).
    static func openTerminal(at folderURL: URL) {
        let terminalURL: URL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        let configuration: NSWorkspace.OpenConfiguration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([folderURL], withApplicationAt: terminalURL, configuration: configuration)
    }
}
