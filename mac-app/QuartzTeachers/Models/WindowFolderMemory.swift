import Foundation

/// Remembers which folder each open window was in — paired with the
/// window's frame, which is how a restored window finds ITS folder.
///
/// The system restores window frames dependably, but the presented value
/// has come back empty in practice, and handing folders out in appearance
/// order swapped them: restoration order is not creation order. The frame
/// is the one property both sides agree on, so it is the key.
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

    /// The folder remembered for a window with this frame, when there is
    /// one. This is what keeps each window's folder with THAT window.
    static func claimFolder(matchingFrame frame: String, defaults: UserDefaults = UserDefaults.standard) -> String? {
        loadIfNeeded(defaults: defaults)
        for (index, entry) in unclaimed.enumerated() {
            if entry.frame == frame && WorkspaceModel.folderExists(atPath: entry.path) {
                unclaimed.remove(at: index)
                return entry.path
            }
        }
        return nil
    }

    /// The next remembered folder in order — the fallback when nothing
    /// matches by frame (the frames were not restored either).
    static func claimNextFolder(defaults: UserDefaults = UserDefaults.standard) -> String? {
        loadIfNeeded(defaults: defaults)
        while !unclaimed.isEmpty {
            let entry: Entry = unclaimed.removeFirst()
            if WorkspaceModel.folderExists(atPath: entry.path) {
                return entry.path
            }
        }
        return nil
    }

    /// True exactly once per launch: the caller becomes the window that
    /// checks for remembered folders still without a window.
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
    static func takeUnclaimed(defaults: UserDefaults = UserDefaults.standard) -> [String] {
        loadIfNeeded(defaults: defaults)
        var remaining: [String] = []
        for entry in unclaimed {
            if WorkspaceModel.folderExists(atPath: entry.path) {
                remaining.append(entry.path)
            }
        }
        unclaimed = []
        return remaining
    }

    /// Records the open windows as folder-and-frame pairs.
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
