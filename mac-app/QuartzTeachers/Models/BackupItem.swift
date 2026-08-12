import Foundation

/// A saved copy of a whole course, made on purpose before risky editing —
/// handing a pile of pages to an LLM, say — so there is always a way back.
///
/// Backups live beside the archives in `courses/_backups/<CODE>/`, told
/// apart by name: a backup is `<CODE>_backup_<timestamp>.zip`, an archive
/// is `<CODE>_<timestamp>.zip`, and the setup wizard's automatic zips are
/// `<timestamp>.zip` alone. Each parser accepts only its own form, so the
/// three kinds can never appear in each other's lists.
struct BackupItem: Identifiable, Hashable {

    // MARK: - Stored properties

    /// The course this is a copy of.
    let courseCode: String

    /// When the copy was made.
    let backedUpAt: Date

    /// Where the zip is, so it can be restored, revealed, or deleted.
    let fileURL: URL

    // MARK: - Computed properties

    var id: String {
        return fileURL.path
    }

    var title: String {
        return courseCode
    }

    /// "11 August 2026 at 10:15 PM" — the moment alone, with the time,
    /// because a careful teacher may make several backups in one evening.
    var whenDescription: String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: backedUpAt)
    }

    /// "Backed up 11 August 2026 at 10:15 PM".
    var subtitle: String {
        return "Backed up \(whenDescription)"
    }

    var symbolName: String {
        return "clock.arrow.circlepath"
    }

    // MARK: - Functions

    /// Reads a backup's name, which is `<CODE>_backup_<timestamp>.zip`.
    /// Returns nil for anything else — archives and the wizard's
    /// automatic zips included.
    static func from(fileURL: URL, courseCode: String) -> BackupItem? {
        if fileURL.pathExtension.lowercased() != "zip" {
            return nil
        }
        let name: String = fileURL.deletingPathExtension().lastPathComponent
        let expectedPrefix: String = "\(courseCode)_backup_"
        if !name.hasPrefix(expectedPrefix) {
            return nil
        }
        let stamp: String = String(name.dropFirst(expectedPrefix.count))
        guard let backedUpAt = ArchivedItem.date(fromStamp: stamp) else {
            return nil
        }
        return BackupItem(courseCode: courseCode, backedUpAt: backedUpAt, fileURL: fileURL)
    }
}
