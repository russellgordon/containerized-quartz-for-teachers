import AppKit
import Foundation

/// Folder-related actions offered by sidebar context menus.
enum FolderActions {

    // MARK: - Functions

    /// Shows the folder inside its parent, selected — what "Show in
    /// Finder" means everywhere in the app, path bar included.
    static func showInFinder(_ folderURL: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([folderURL])
    }

    /// Opens a new Terminal window whose working directory is the folder
    /// (the same behaviour as dropping the folder onto Terminal's icon).
    static func openTerminal(at folderURL: URL) {
        let terminalURL: URL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        let configuration: NSWorkspace.OpenConfiguration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([folderURL], withApplicationAt: terminalURL, configuration: configuration)
    }

    /// Opens the folder in Obsidian. A vault is just a folder of text
    /// files, and Obsidian's own URL scheme finds the vault a path belongs
    /// to — or offers to make the folder one if none does.
    static func openInObsidian(_ folderURL: URL) {
        guard let obsidianURL = FolderActions.obsidianURL(forFolder: folderURL) else {
            return
        }
        NSWorkspace.shared.open(obsidianURL)
    }

    /// The `obsidian://open?path=…` link for a folder, with the path
    /// properly percent-encoded.
    static func obsidianURL(forFolder folderURL: URL) -> URL? {
        var components: URLComponents = URLComponents()
        components.scheme = "obsidian"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "path", value: folderURL.path)]
        return components.url
    }

    /// Whether anything on this Mac answers `obsidian://` links — the
    /// menu item and button stay visible either way, but a click can only
    /// do something when Obsidian is installed.
    static var obsidianIsInstalled: Bool {
        guard let probe = URL(string: "obsidian://open") else {
            return false
        }
        return NSWorkspace.shared.urlForApplication(toOpen: probe) != nil
    }
}
