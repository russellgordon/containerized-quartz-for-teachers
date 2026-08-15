import Foundation

/// The section windows that are on screen, and the preview each one owns.
///
/// **Why a registry of closures rather than a request an observer notices.**
/// The assistant needs to do three things in order — stop the preview, change
/// the files, start it again — and the middle step must not begin until the
/// first has finished. A request that a view observes and acts on later cannot
/// express that: the runner posts, carries on, and the window stops the
/// preview at whatever moment SwiftUI next evaluates a body, which may be
/// after the writes. That is exactly the fault this replaced. It also failed
/// silently, which is worse than failing: the files changed, the preview did
/// not move, and nothing anywhere said why.
///
/// So the window hands over the two things it alone can do, and the runner
/// calls them directly, in order, on the main actor. Ordering becomes ordinary
/// sequential code.
///
/// **Why the window still owns them.** A preview is a server on a leased port
/// and a web view; both belong to the section window, and the assistant has
/// neither. Registering the window's own `startPreview()` and `stopPreview()`
/// means the assistant and the toolbar button run the SAME code rather than
/// two versions of it that drift.
///
/// Nothing registered is not an error. A teacher can change pages with no
/// section window open at all, and then there is no preview to cycle — the
/// caller builds the site and says so.
@MainActor
final class SectionPreviewControllers {

    // MARK: - Types

    /// Which section a window is showing.
    struct Key: Hashable {

        // MARK: - Stored properties

        let folderPath: String
        let courseCode: String
        let sectionNumber: Int

        // MARK: - Initializer

        init(folderPath: String, courseCode: String, sectionNumber: Int) {
            // Standardised and case-folded on the way IN, so a caller cannot
            // fail to match by spelling the same folder a different way. The
            // previous mechanism compared raw strings, and a mismatch there
            // would have been invisible.
            self.folderPath = URL(fileURLWithPath: folderPath).standardizedFileURL.path
            self.courseCode = courseCode.lowercased()
            self.sectionNumber = sectionNumber
        }
    }

    /// What a section window can be asked to do about its preview.
    struct Controller {

        // MARK: - Stored properties

        let isRunning: () -> Bool
        let start: () -> Void

        /// Asynchronous, and that is the whole point of it.
        ///
        /// Stopping a preview reaches into the container and kills the
        /// processes belonging to that section. Started as fire-and-forget —
        /// which is right behind a button, where the teacher has already moved
        /// on — it is still running when the next preview begins, and kills
        /// that one too. Awaiting it is what makes "stop, write, start" mean
        /// what it says.
        let stop: () async -> Void
    }

    // MARK: - Stored properties

    private var controllers: [Key: Controller] = [:]

    static let shared: SectionPreviewControllers = SectionPreviewControllers()

    // MARK: - Functions

    /// A section window says it is on screen and can drive its preview.
    func register(
        folderPath: String,
        courseCode: String,
        sectionNumber: Int,
        controller: Controller
    ) {
        controllers[Key(folderPath: folderPath, courseCode: courseCode, sectionNumber: sectionNumber)]
            = controller
    }

    /// A section window says it has gone.
    func unregister(folderPath: String, courseCode: String, sectionNumber: Int) {
        controllers.removeValue(
            forKey: Key(folderPath: folderPath, courseCode: courseCode, sectionNumber: sectionNumber)
        )
    }

    /// The window showing this section, if one is open.
    func controller(folderPath: String, courseCode: String, sectionNumber: Int) -> Controller? {
        return controllers[
            Key(folderPath: folderPath, courseCode: courseCode, sectionNumber: sectionNumber)
        ]
    }

    /// Forget everything. Tests only — the app's windows manage their own.
    func forgetAll() {
        controllers.removeAll()
    }
}
