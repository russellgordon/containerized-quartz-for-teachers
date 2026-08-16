import Foundation
@testable import QuartzTeachers

/// A stand-in for a section window, which records the ORDER of what the
/// assistant did to it — its preview, and its Deploy.
///
/// The order is the point. Stopping, writing and starting can all happen and
/// still be wrong: a preview stopped after the pages were rewritten was
/// serving a half-changed site in between, and that is exactly the fault the
/// first attempt at this had. So this notes a "write" the moment the watched
/// page changes on disk, and the test reads the three events back as a
/// sequence rather than as a set.
@MainActor
final class FakePreview {

    // MARK: - Stored properties

    static let shared: FakePreview = FakePreview()

    private(set) var events: [String] = []
    private var running: Bool = true
    private var watchedURL: URL?
    private var textWhenWatched: String?

    // MARK: - Functions

    /// Pretend a section window is open and showing a running preview.
    func register(folderPath: String, courseCode: String, sectionNumber: Int) {
        events = []
        running = true
        watchedURL = nil
        textWhenWatched = nil
        SectionWindowControllers.shared.register(
            folderPath: folderPath,
            courseCode: courseCode,
            sectionNumber: sectionNumber,
            controller: SectionWindowControllers.Controller(
                isPreviewRunning: { [weak self] in self?.running ?? false },
                startPreview: { [weak self] in
                    self?.noteWriteIfItHappened()
                    self?.running = true
                    self?.events.append("start")
                },
                stopPreview: { [weak self] in
                    // Records the stop as two events with a real suspension
                    // between them, so the test can tell "called the stop"
                    // apart from "waited for the stop to finish". The real
                    // one reaches into the container and takes time; a caller
                    // that does not await it starts a rebuild the stop then
                    // kills.
                    self?.noteWriteIfItHappened()
                    self?.events.append("stop-begins")
                    try? await Task.sleep(for: .milliseconds(60))
                    self?.running = false
                    self?.noteWriteIfItHappened()
                    self?.events.append("stop-ends")
                },
                // The window's Deploy, which the assistant presses rather
                // than running the launcher where nobody can see it. It goes
                // into the same sequence as the preview events, because the
                // order is the whole question: deploying while the preview is
                // still up is what the button in the window will not let a
                // teacher do.
                deploy: { [weak self] in
                    self?.events.append("deploy")
                    return AssistSiteWorkResult(
                        succeeded: true, message: "ICS3U Section 1 is deployed."
                    )
                }
            )
        )
    }

    /// Watch a page, so a change to it lands in the sequence as "write".
    func watch(pageAt url: URL) {
        watchedURL = url
        textWhenWatched = try? String(contentsOf: url, encoding: .utf8)
    }

    func forget() {
        SectionWindowControllers.shared.forgetAll()
        events = []
        watchedURL = nil
        textWhenWatched = nil
    }

    // MARK: - Private

    private func noteWriteIfItHappened() {
        guard let watchedURL, events.last != "write" else {
            return
        }
        let now: String? = try? String(contentsOf: watchedURL, encoding: .utf8)
        if now != textWhenWatched {
            textWhenWatched = now
            events.append("write")
        }
    }
}
