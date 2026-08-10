import Foundation

/// Hands out preview ports, one per running preview, across every window.
///
/// The container publishes ports 8081–8084, so up to four previews can run
/// at once — a teacher comparing sections side by side. Each preview leases
/// a port when it starts and returns it when it stops; the same section can
/// only be previewed in one place, because two builds of one section would
/// race over the same output folder.
@MainActor
enum PreviewLeases {

    // MARK: - Types

    struct Lease: Equatable {
        let port: Int
        let folderPath: String
        let courseCode: String
        let sectionNumber: Int
    }

    /// Why a preview could not start, in words a teacher can act on.
    enum Problem: LocalizedError {
        case sectionAlreadyPreviewed(String, Int)
        case allPortsBusy

        var errorDescription: String? {
            switch self {
            case .sectionAlreadyPreviewed(let code, let section):
                return "Section \(section) of \(code) is already being previewed in another window. Stop that preview first, or work with it there."
            case .allPortsBusy:
                return "Four previews are already running, which is the most that can run at once. Stop one, then try again."
            }
        }
    }

    // MARK: - Stored properties

    /// The ports the container publishes.
    static let availablePorts: [Int] = [8081, 8082, 8083, 8084]

    /// The previews currently running, across all windows.
    private(set) static var active: [Lease] = []

    // MARK: - Functions

    /// Leases a port for a preview of one section, refusing politely when
    /// the section is already live elsewhere or every port is taken.
    static func lease(folderPath: String, courseCode: String, sectionNumber: Int) throws -> Lease {
        for existing in active {
            let samePlace: Bool = existing.folderPath == folderPath
                && existing.courseCode == courseCode
                && existing.sectionNumber == sectionNumber
            if samePlace {
                throw Problem.sectionAlreadyPreviewed(courseCode, sectionNumber)
            }
        }

        var takenPorts: [Int] = []
        for existing in active {
            takenPorts.append(existing.port)
        }
        for port in availablePorts {
            if !takenPorts.contains(port) {
                let lease: Lease = Lease(
                    port: port,
                    folderPath: folderPath,
                    courseCode: courseCode,
                    sectionNumber: sectionNumber
                )
                active.append(lease)
                return lease
            }
        }
        throw Problem.allPortsBusy
    }

    /// Returns a lease when its preview stops, whatever the reason.
    static func release(_ lease: Lease) {
        var remaining: [Lease] = []
        for existing in active {
            if existing != lease {
                remaining.append(existing)
            }
        }
        active = remaining
    }

    /// Starts from nothing — for tests.
    static func reset() {
        active = []
    }
}
