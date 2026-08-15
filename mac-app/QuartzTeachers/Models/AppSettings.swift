import Foundation
import Observation

/// Settings that belong to the TEACHER rather than to any one course.
///
/// The Cloudflare Account ID is the first of these. It identifies the
/// person, not the class — a teacher deploying four courses to Cloudflare
/// has one account for all of them — so storing it in `course_config.json`
/// would ask the same question once per course and then leave four copies
/// to drift apart. That is the same reasoning that puts the API token in
/// the Keychain rather than in the course folder.
///
/// The store is injectable so that tests never write into the teacher's
/// real preferences, following `WorkspaceModel` and `WindowFolderMemory`.
@Observable
class AppSettings {

    // MARK: - Stored properties

    /// The app's own settings, used by every window.
    @MainActor static let shared: AppSettings = AppSettings()

    /// Where these are remembered. Injected so a test can never write into
    /// the real preferences.
    @ObservationIgnored private let defaults: UserDefaults

    /// The key holding the Cloudflare Account ID.
    static let cloudflareAccountIDKey: String = "cloudflareAccountID"

    /// The teacher's Cloudflare Account ID, entered once and used by every
    /// course that deploys to Cloudflare Pages. Empty until they give it.
    var cloudflareAccountID: String {
        didSet {
            if canRemember {
                defaults.set(cloudflareAccountID, forKey: AppSettings.cloudflareAccountIDKey)
            }
        }
    }

    // MARK: - Computed properties

    /// False while the hosted tests drive the real app, so a test run
    /// cannot leave a fixture value behind in the teacher's preferences.
    private var canRemember: Bool {
        if WorkspaceModel.isRunningTests && defaults === UserDefaults.standard {
            return false
        }
        return true
    }

    // MARK: - Initializer

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
        self.cloudflareAccountID = defaults.string(forKey: AppSettings.cloudflareAccountIDKey) ?? ""
    }
}
