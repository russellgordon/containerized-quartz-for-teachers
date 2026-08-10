import Foundation

/// The fallback that reopens windows when macOS restores nothing.
///
/// The real mechanism is `WindowGroup(for: WindowFolder.self)`: each window
/// carries its folder in its restoration state and comes back with it. But
/// restoration is easily lost — the app rebuilt, killed from Xcode, or the
/// "Close windows when quitting" setting switched on — and the windows
/// should come back anyway. This list, written down while the windows were
/// still open, is what makes that possible.
@MainActor
enum WindowFolderMemory {

    // MARK: - Stored properties

    /// Where the list is kept between launches.
    static let storageKey: String = "openWindowFolders"

    /// Folders not yet taken by a window this launch.
    private static var unclaimedFolders: [String] = []

    private static var hasLoaded: Bool = false
    private static var hasRunSpawnCheck: Bool = false

    // MARK: - Functions

    /// The folder a fresh, blank window should open in — the next
    /// remembered one, skipping any that no longer exist. Windows the
    /// system restored carry their own folder and never ask.
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

    /// True exactly once per launch: the caller becomes the window that
    /// checks whether any remembered folders still have no window, and
    /// opens them.
    static func beginSpawnCheckOnce() -> Bool {
        if hasRunSpawnCheck {
            return false
        }
        hasRunSpawnCheck = true
        return true
    }

    /// The remembered folders no window has claimed, handed over for
    /// spawning. Claiming ends here: a window opened by the teacher later
    /// in the session must start fresh, not inherit a stale leftover.
    static func takeUnclaimed(defaults: UserDefaults = UserDefaults.standard) -> [String] {
        loadIfNeeded(defaults: defaults)
        var remaining: [String] = []
        for candidate in unclaimedFolders {
            if WorkspaceModel.folderExists(atPath: candidate) {
                remaining.append(candidate)
            }
        }
        unclaimedFolders = []
        return remaining
    }

    /// Records the folders currently open, in window order.
    static func record(_ folders: [String], defaults: UserDefaults = UserDefaults.standard) {
        if WorkspaceModel.isRunningTests && defaults == UserDefaults.standard {
            return
        }
        defaults.set(folders, forKey: storageKey)
    }

    private static func loadIfNeeded(defaults: UserDefaults) {
        if hasLoaded {
            return
        }
        hasLoaded = true
        unclaimedFolders = defaults.stringArray(forKey: storageKey) ?? []
    }

    /// Starts again from a given list — for tests.
    static func reset(with folders: [String]) {
        unclaimedFolders = folders
        hasLoaded = true
        hasRunSpawnCheck = false
    }
}
