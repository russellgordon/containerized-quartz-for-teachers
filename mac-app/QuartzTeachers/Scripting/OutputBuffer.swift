import Foundation

/// A thread-safe holding pen for script output.
///
/// Chunks arrive on a background reading queue, often far faster than
/// the interface can absorb them; they wait here until the next flush.
nonisolated final class OutputBuffer: @unchecked Sendable {

    // MARK: - Stored properties

    private let lock: NSLock = NSLock()
    private var text: String = ""
    private var chunkCount: Int = 0
    private var isFlushScheduled: Bool = false

    // MARK: - Functions

    /// Stores a chunk. Returns true when the caller should schedule a
    /// flush (i.e. no flush is already pending).
    nonisolated func add(_ chunk: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        text += chunk
        chunkCount += 1
        if isFlushScheduled {
            return false
        }
        isFlushScheduled = true
        return true
    }

    /// Takes everything buffered so far.
    nonisolated func take() -> (text: String, chunkCount: Int) {
        lock.lock()
        defer { lock.unlock() }
        let result: (text: String, chunkCount: Int) = (text: text, chunkCount: chunkCount)
        text = ""
        chunkCount = 0
        isFlushScheduled = false
        return result
    }
}
