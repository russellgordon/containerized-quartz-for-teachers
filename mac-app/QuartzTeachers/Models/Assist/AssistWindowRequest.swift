import Foundation

/// Which section an assistant window is about.
///
/// The value a `WindowGroup` is keyed by, so opening the assistant twice for
/// the same section brings the existing window forward instead of starting a
/// second copy — which would mean a second `llama-server`, a second few
/// gigabytes of the teacher's memory, and two conversations that each think
/// they are the only one making changes.
struct AssistWindowRequest: Hashable, Codable, Identifiable {

    // MARK: - Stored properties

    let courseCode: String
    let sectionNumber: Int
    let workingFolder: URL

    // MARK: - Computed properties

    var id: String {
        return "\(workingFolder.path)#\(courseCode)#\(sectionNumber)"
    }
}
