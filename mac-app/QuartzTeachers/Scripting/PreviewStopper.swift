import Foundation

/// Reclaims the container-side processes of a preview that just ended.
///
/// Stopping a preview (the Stop Preview button, clicking away from the
/// section, closing the window) terminates the HOST-side launcher — but
/// the build or server processes inside the container would keep running:
/// idle for a server, real CPU for a mid-flight build. This runs the
/// launcher's stop mode quietly in the background to end them too.
@MainActor
enum PreviewStopper {

    // MARK: - Stored properties

    /// Keeps each stop process alive until it finishes.
    private(set) static var running: [Process] = []

    // MARK: - Functions

    /// Fire-and-forget: asks the launcher to stop the section's
    /// container-side processes. Quiet by design — this runs behind
    /// actions that already have their own feedback, and if it cannot
    /// run, the next preview of the section frees its ports anyway.
    static func stopSectionProcesses(courseCode: String, sectionNumber: Int, workspaceURL: URL) {
        let scriptURL: URL = workspaceURL.appendingPathComponent("preview.sh")
        if !FileManager.default.fileExists(atPath: scriptURL.path) {
            return
        }

        let process: Process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path, courseCode, String(sectionNumber), "--stop"]
        process.currentDirectoryURL = workspaceURL
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { finished in
            Task { @MainActor in
                var remaining: [Process] = []
                for candidate in running {
                    if candidate !== finished {
                        remaining.append(candidate)
                    }
                }
                running = remaining
            }
        }

        do {
            try process.run()
            running.append(process)
        } catch {
            // Could not start: nothing held, nothing to clean up.
        }
    }
}
