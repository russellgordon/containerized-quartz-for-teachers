import Foundation
import Observation

/// The way the assistant asks a section's own window to put its preview on
/// screen.
///
/// **Why it cannot just do it.** The preview is not only a build: it is a
/// server on a leased port and a web view showing it, and both belong to the
/// section window. The assistant runs in a window of its own that holds
/// neither. So for a long time it did the only half it could reach — it built
/// the site with `--build-only` and told the teacher to go and look — which
/// produced the one thing an assistant must never produce: a confident report
/// of success beside a window reading "No Preview Running".
///
/// So it asks, exactly as `SectionSchedulePrompt` asks for class dates. The
/// section window answers by pressing its own Preview, which means the
/// assistant and the button run identical code rather than similar code, and
/// cannot drift apart later.
///
/// **Already-running previews are left alone.** The button is a toggle — press
/// it while a preview is up and it STOPS — and an assistant that stopped a
/// teacher's running preview because they asked to see it would be absurd.
/// The window therefore starts one only when none is running; when one is, the
/// rebuild the assistant has already done is what the running server serves.
@MainActor
@Observable
final class SectionPreviewRequests {

    // MARK: - Types

    /// Which section should be showing a preview.
    struct Request: Identifiable, Equatable {

        // MARK: - Stored properties

        let folderPath: String
        let courseCode: String
        let sectionNumber: Int

        /// Distinguishes two asks for the SAME section, which are otherwise
        /// identical and would not register as a change. Asking twice is
        /// ordinary — a teacher publishes two things in a row — and the
        /// second ask must not be swallowed.
        let count: Int

        // MARK: - Computed properties

        var id: String {
            return "\(folderPath)#\(courseCode)#\(sectionNumber)#\(count)"
        }
    }

    // MARK: - Stored properties

    /// The outstanding ask, if any.
    private(set) var request: Request?

    /// How many asks there have been, so each is its own value.
    private var asked: Int = 0

    static let shared: SectionPreviewRequests = SectionPreviewRequests()

    // MARK: - Functions

    /// Ask the window showing this section to put its preview up.
    func ask(folderPath: String, courseCode: String, sectionNumber: Int) {
        asked += 1
        request = Request(
            folderPath: folderPath,
            courseCode: courseCode,
            sectionNumber: sectionNumber,
            count: asked
        )
    }

    /// Whether a request is for the section a particular window is showing.
    func isFor(_ request: Request, folderPath: String, courseCode: String, sectionNumber: Int) -> Bool {
        return request.folderPath == folderPath
            && request.courseCode.lowercased() == courseCode.lowercased()
            && request.sectionNumber == sectionNumber
    }

    /// Answered, or nothing was listening.
    func stopAsking() {
        request = nil
    }
}
