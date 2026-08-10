import Foundation
import OSLog

/// Runtime logging, viewable in Console.app by filtering on the
/// subsystem below (or from a terminal with:
/// `log stream --predicate 'subsystem == "ca.russellgordon.QuartzTeachers"'`).
enum AppLog {

    // MARK: - Stored properties

    static let subsystem: String = "ca.russellgordon.QuartzTeachers"

    /// Script output arriving, coalescing, and milestone progress.
    static let output: Logger = Logger(subsystem: subsystem, category: "output")

    /// Interface responsiveness — notably any stall between refreshes.
    static let interface: Logger = Logger(subsystem: subsystem, category: "interface")
}
