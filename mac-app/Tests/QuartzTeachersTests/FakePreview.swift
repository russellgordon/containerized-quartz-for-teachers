import Foundation
@testable import QuartzTeachers

/// A stand-in for a section window's preview, which records the ORDER of what
/// the assistant did to it.
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
        SectionPreviewControllers.shared.register(
            folderPath: folderPath,
            courseCode: courseCode,
            sectionNumber: sectionNumber,
            controller: SectionPreviewControllers.Controller(
                isRunning: { [weak self] in self?.running ?? false },
                start: { [weak self] in
                    self?.noteWriteIfItHappened()
                    self?.running = true
                    self?.events.append("start")
                },
                stop: { [weak self] in
                    self?.noteWriteIfItHappened()
                    self?.running = false
                    self?.events.append("stop")
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
        SectionPreviewControllers.shared.forgetAll()
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
