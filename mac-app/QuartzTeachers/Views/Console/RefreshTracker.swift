import Foundation

/// Remembers when the progress header last refreshed.
///
/// Deliberately a plain class with no observation: the tracker is
/// written DURING view body evaluation, and writing observed state
/// there re-invalidates the view, spinning the main thread in an
/// endless body → state change → body loop.
final class RefreshTracker {

    // MARK: - Stored properties

    var lastRefreshAt: Date = Date()

    /// How many refreshes have happened, for occasional diagnostics.
    var refreshCount: Int = 0
}
