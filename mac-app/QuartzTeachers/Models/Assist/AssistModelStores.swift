import Foundation

/// One store per rung, for the whole app.
///
/// **The bug this exists to stop is a double download.** There is one file per
/// rung on the disk, but there used to be one `AssistModelStore` per PLACE
/// that cared: the settings panel made its own, and every assistant window
/// made another. A teacher who pressed Download in Settings and then opened
/// the assistant while it ran got a second store looking at the same path,
/// seeing an incomplete file, deleting it — that is what `download()` does to
/// a part-finished attempt, deliberately — and starting again. Two transfers
/// writing to one destination, each undoing the other, on a school connection,
/// for gigabytes.
///
/// Sharing also fixes the quieter half. A download started in one place is now
/// visible in the other, because both are watching the same observable object:
/// open Settings while the assistant is fetching its model and the progress is
/// simply there, rather than the panel insisting nothing is downloaded.
///
/// Keyed by tier rather than by path because the tier IS the identity — the
/// path is derived from it, and a tier's file cannot be two things at once.
@MainActor
enum AssistModelStores {

    // MARK: - Stored properties

    private static var stores: [AssistModelTier: AssistModelStore] = [:]

    // MARK: - Functions

    /// The one store for this rung, made on first use.
    static func store(for tier: AssistModelTier) -> AssistModelStore {
        if let existing = stores[tier] {
            return existing
        }
        let made: AssistModelStore = AssistModelStore(tier: tier)
        stores[tier] = made
        return made
    }

    /// Forget everything, for tests.
    ///
    /// Process-wide state that outlives a test is the failure this project has
    /// already been bitten by — see the note in CLAUDE.md about the mac suite
    /// running its classes one at a time. A store cached against one test's
    /// temporary models folder would answer questions about the next test's.
    static func reset() {
        for (_, store) in stores {
            store.cancel()
        }
        stores = [:]
    }
}
