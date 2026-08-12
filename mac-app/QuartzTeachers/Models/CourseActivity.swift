import Foundation

/// Which courses are doing something right now, across every window:
/// previewing (known via `PreviewLeases`) or publishing (recorded here).
///
/// Re-running the course setup rewrites a course's folders and files, so
/// actions like "Add Section…" must decline while one of the course's
/// sections is previewing or publishing — the setup run and the build
/// could stomp on each other's files.
@MainActor
enum CourseActivity {

    // MARK: - Types

    struct PublishRecord: Equatable {
        let folderPath: String
        let courseCode: String
        let sectionNumber: Int
    }

    // MARK: - Stored properties

    /// The publishes currently running, across all windows.
    private(set) static var activePublishes: [PublishRecord] = []

    // MARK: - Functions

    /// Records that a publish of one section has begun.
    static func beginPublish(folderPath: String, courseCode: String, sectionNumber: Int) {
        let record: PublishRecord = PublishRecord(
            folderPath: folderPath,
            courseCode: courseCode,
            sectionNumber: sectionNumber
        )
        activePublishes.append(record)
    }

    /// Records that a publish has finished, however it finished.
    static func endPublish(folderPath: String, courseCode: String, sectionNumber: Int) {
        let finished: PublishRecord = PublishRecord(
            folderPath: folderPath,
            courseCode: courseCode,
            sectionNumber: sectionNumber
        )
        var remaining: [PublishRecord] = []
        var didRemoveOne: Bool = false
        for existing in activePublishes {
            if existing == finished && !didRemoveOne {
                didRemoveOne = true
                continue
            }
            remaining.append(existing)
        }
        activePublishes = remaining
    }

    /// True while any section of the course is previewing or publishing.
    static func courseIsBusy(folderPath: String, courseCode: String) -> Bool {
        for lease in PreviewLeases.active {
            if lease.folderPath == folderPath && lease.courseCode == courseCode {
                return true
            }
        }
        for publish in activePublishes {
            if publish.folderPath == folderPath && publish.courseCode == courseCode {
                return true
            }
        }
        return false
    }

    /// Starts from nothing — for tests.
    static func reset() {
        activePublishes = []
    }
}
