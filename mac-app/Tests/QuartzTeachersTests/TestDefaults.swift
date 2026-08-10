import Foundation

/// A throwaway preferences store for tests.
///
/// Tests used to call `chooseWorkspace(at:)` with temporary fixture folders,
/// and those writes landed in the app's real preferences — so after a test
/// run the app launched pointing at a folder that had just been deleted, and
/// looked as though it had forgotten its working folder.
enum TestDefaults {

    // MARK: - Functions

    static func make() -> UserDefaults {
        let name: String = "test-" + UUID().uuidString
        guard let defaults = UserDefaults(suiteName: name) else {
            return UserDefaults.standard
        }
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
