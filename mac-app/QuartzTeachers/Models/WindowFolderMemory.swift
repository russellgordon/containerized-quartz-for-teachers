import Foundation

/// Remembers which folder each open window was working in, so the windows
/// come back the way they were left.
///
/// `@SceneStorage` is the obvious tool for this and does not work here: two
/// windows of one `WindowGroup` share a value, so whichever window wrote
/// last decides what every window restores — which is exactly the fault this
/// replaces. This keeps its own ordered list instead, and hands the folders
/// out to windows in the order they appear.
@MainActor
enum WindowFolderMemory {

    // MARK: - Stored properties

    /// Where the list is kept between launches.
    static let storageKey: String = "openWindowFolders"

    /// Folders not yet taken by a window this launch.
    private static var unclaimedFolders: [String] = []

    /// Whether the list has been read from the store yet.
    private static var hasLoaded: Bool = false

    // MARK: - Functions

    /// The folder the next window to appear should open, or nil once the
    /// remembered windows have all been given one.
    ///
    /// A folder that has since been deleted is skipped rather than handed
    /// out: a window pointed at a folder that is gone is worse than a
    /// window that simply opens where the teacher last was.
    static func claimNextFolder(defaults: UserDefaults = UserDefaults.standard) -> String? {
        loadIfNeeded(defaults: defaults)
        while !unclaimedFolders.isEmpty {
            let candidate: String = unclaimedFolders.removeFirst()
            if WorkspaceModel.folderExists(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    /// Records the folders currently open, in window order.
    static func record(_ folders: [String], defaults: UserDefaults = UserDefaults.standard) {
        if WorkspaceModel.isRunningTests && defaults == UserDefaults.standard {
            return
        }
        defaults.set(folders, forKey: storageKey)
    }

    /// Reads the list one window at a time would otherwise race over.
    private static func loadIfNeeded(defaults: UserDefaults) {
        if hasLoaded {
            return
        }
        hasLoaded = true
        let stored: [String] = defaults.stringArray(forKey: storageKey) ?? []
        unclaimedFolders = stored
    }

    /// Starts again from a given list — for tests, which cannot rely on
    /// whatever the previous test left behind.
    static func reset(with folders: [String]) {
        unclaimedFolders = folders
        hasLoaded = true
    }
}
