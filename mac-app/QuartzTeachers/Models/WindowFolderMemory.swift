import Foundation

/// Remembers each open window's folder and frame, and hands them back at
/// the next launch.
///
/// The app restores its own windows from this list: the first window takes
/// the first entry, and one spawn pass opens a window for each remaining
/// entry. With system restoration disabled there is exactly one launch
/// window, so the order is deterministic — the windows come back in the
/// order they were open.
@MainActor
enum WindowFolderMemory {

    // MARK: - Types

    struct Entry {
        let path: String
        let frame: String
    }

    // MARK: - Stored properties

    /// Where the list is kept between launches.
    static let storageKey: String = "openWindowFolders"

    /// Entries not yet taken by a window this launch.
    private static var unclaimed: [Entry] = []

    private static var hasLoaded: Bool = false
    private static var hasRunSpawnCheck: Bool = false

    // MARK: - Functions

    /// The next remembered window, skipping folders that no longer exist.
    static func claimNextEntry(defaults: UserDefaults = UserDefaults.standard) -> Entry? {
        loadIfNeeded(defaults: defaults)
        while !unclaimed.isEmpty {
            let entry: Entry = unclaimed.removeFirst()
            if WorkspaceModel.folderExists(atPath: entry.path) {
                return entry
            }
        }
        return nil
    }

    /// True exactly once per launch: the caller becomes the window that
    /// opens the remaining remembered windows.
    static func beginSpawnCheckOnce() -> Bool {
        if hasRunSpawnCheck {
            return false
        }
        hasRunSpawnCheck = true
        return true
    }

    /// The entries no window has claimed, handed over for spawning.
    /// Claiming ends here: a window the teacher opens later must start
    /// fresh, not inherit a stale leftover.
    static func takeUnclaimed(defaults: UserDefaults = UserDefaults.standard) -> [Entry] {
        loadIfNeeded(defaults: defaults)
        var remaining: [Entry] = []
        for entry in unclaimed {
            if WorkspaceModel.folderExists(atPath: entry.path) {
                remaining.append(entry)
            }
        }
        unclaimed = []
        return remaining
    }

    /// Records the open windows as folder-and-frame pairs, in order.
    static func record(_ entries: [Entry], defaults: UserDefaults = UserDefaults.standard) {
        if WorkspaceModel.isRunningTests && defaults == UserDefaults.standard {
            return
        }
        var stored: [[String: String]] = []
        for entry in entries {
            stored.append(["path": entry.path, "frame": entry.frame])
        }
        defaults.set(stored, forKey: storageKey)
    }

    private static func loadIfNeeded(defaults: UserDefaults) {
        if hasLoaded {
            return
        }
        hasLoaded = true
        var loaded: [Entry] = []
        if let stored = defaults.array(forKey: storageKey) {
            for element in stored {
                if let pair = element as? [String: String], let path = pair["path"] {
                    loaded.append(Entry(path: path, frame: pair["frame"] ?? ""))
                }
                // An entry from the earlier format: a bare path string.
                if let path = element as? String {
                    loaded.append(Entry(path: path, frame: ""))
                }
            }
        }
        unclaimed = loaded
    }

    /// Starts again from a given list — for tests.
    static func reset(with entries: [Entry]) {
        unclaimed = entries
        hasLoaded = true
        hasRunSpawnCheck = false
    }
}
