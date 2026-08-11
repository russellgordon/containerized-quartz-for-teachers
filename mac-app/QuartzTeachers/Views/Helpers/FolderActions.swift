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

    /// Opens the folder in Obsidian. Obsidian's `open?path=` link only
    /// works for folders inside a vault it already KNOWS — its registry at
    /// `~/Library/Application Support/obsidian/obsidian.json` — so a course
    /// it has never seen is registered first, exactly the way Obsidian's
    /// own "Open folder as vault" writes the entry. A running Obsidian
    /// keeps its vault list in memory, so registering means quitting it
    /// first (it restores its windows on relaunch); doing the quit before
    /// the write also stops Obsidian overwriting the new entry on exit.
    static func openInObsidian(revealing folderURL: URL, vaultURL: URL) {
        guard let obsidianLink = FolderActions.obsidianURL(forFolder: folderURL) else {
            return
        }
        let registryData: Data? = try? Data(contentsOf: FolderActions.obsidianRegistryFileURL)
        if FolderActions.folderIsInRegisteredVault(folderURL.path, registryData: registryData) {
            NSWorkspace.shared.open(obsidianLink)
            return
        }
        Task { @MainActor in
            await FolderActions.quitObsidianAndWait()
            FolderActions.seedObsidianDefaultsIfMissing(inVault: vaultURL)
            FolderActions.registerVault(at: vaultURL)
            NSWorkspace.shared.open(obsidianLink)
        }
    }

    /// Where Obsidian keeps its list of known vaults.
    static var obsidianRegistryFileURL: URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/obsidian/obsidian.json")
    }

    /// Whether the folder sits inside (or is) a vault Obsidian already
    /// knows about.
    static func folderIsInRegisteredVault(_ folderPath: String, registryData: Data?) -> Bool {
        guard let registryData else {
            return false
        }
        guard let registry = try? JSONSerialization.jsonObject(with: registryData) as? [String: Any] else {
            return false
        }
        guard let vaults = registry["vaults"] as? [String: Any] else {
            return false
        }
        for vaultEntry in vaults.values {
            guard let vault = vaultEntry as? [String: Any] else {
                continue
            }
            guard let vaultPath = vault["path"] as? String else {
                continue
            }
            if folderPath == vaultPath || folderPath.hasPrefix(vaultPath + "/") {
                return true
            }
        }
        return false
    }

    /// The registry with one more vault in it — built from the existing
    /// data so every vault the teacher already has is preserved, or from
    /// nothing when Obsidian has never made a registry at all.
    static func registryData(afterRegisteringVaultAt vaultPath: String, in registryData: Data?, identifier: String, timestamp: Int) -> Data? {
        var registry: [String: Any] = [:]
        if let registryData,
           let existing = try? JSONSerialization.jsonObject(with: registryData) as? [String: Any] {
            registry = existing
        }
        var vaults: [String: Any] = (registry["vaults"] as? [String: Any]) ?? [:]
        vaults[identifier] = ["path": vaultPath, "ts": timestamp]
        registry["vaults"] = vaults
        return try? JSONSerialization.data(withJSONObject: registry)
    }

    /// Adds the vault to Obsidian's registry on disk.
    static func registerVault(at vaultURL: URL) {
        let registryFileURL: URL = FolderActions.obsidianRegistryFileURL
        let existingData: Data? = try? Data(contentsOf: registryFileURL)
        var identifier: String = ""
        for _ in 1...16 {
            identifier.append("0123456789abcdef".randomElement() ?? "0")
        }
        let timestamp: Int = Int(Date().timeIntervalSince1970 * 1000)
        guard let updated = FolderActions.registryData(
            afterRegisteringVaultAt: vaultURL.path,
            in: existingData,
            identifier: identifier,
            timestamp: timestamp
        ) else {
            return
        }
        try? FileManager.default.createDirectory(
            at: registryFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? updated.write(to: registryFileURL)
    }

    /// Quits Obsidian and waits for it to be gone, so the registry write
    /// that follows cannot be overwritten and the relaunch reads it fresh.
    static func quitObsidianAndWait() async {
        let obsidianBundleID: String = "md.obsidian"
        let running: [NSRunningApplication] = NSRunningApplication.runningApplications(withBundleIdentifier: obsidianBundleID)
        if running.isEmpty {
            return
        }
        for application in running {
            application.terminate()
        }
        var attemptsLeft: Int = 50
        while attemptsLeft > 0 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if NSRunningApplication.runningApplications(withBundleIdentifier: obsidianBundleID).isEmpty {
                return
            }
            attemptsLeft -= 1
        }
    }

    /// Copies the toolchain's bundled `.obsidian` defaults into a vault
    /// that has none — the same defaults every wizard-built course gets,
    /// so attachments land in Media rather than beside the notes.
    static func seedObsidianDefaultsIfMissing(inVault vaultURL: URL) {
        let fileManager: FileManager = FileManager.default
        let destination: URL = vaultURL.appendingPathComponent(".obsidian")
        if fileManager.fileExists(atPath: destination.path) {
            return
        }
        guard let resourceURL = Bundle.main.resourceURL else {
            return
        }
        let bundledDefaults: URL = resourceURL.appendingPathComponent("support/obsidian_defaults/.obsidian")
        if fileManager.fileExists(atPath: bundledDefaults.path) {
            try? fileManager.copyItem(at: bundledDefaults, to: destination)
        }
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
