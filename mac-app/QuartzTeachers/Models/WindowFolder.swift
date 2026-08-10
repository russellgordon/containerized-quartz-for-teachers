import Foundation

/// The value a window is presented for: which folder it is working in and
/// where the window sits.
///
/// The app restores its own windows from these — system window restoration
/// is disabled, having proven itself unreliable here three different ways:
/// values came back empty, windows came back in a different order than they
/// were created, and the count drifted as the two mechanisms overlapped.
///
/// The `id` keeps every value distinct: windows presented for equal values
/// are treated as the same window.
struct WindowFolder: Codable, Hashable {

    // MARK: - Stored properties

    let id: UUID
    var path: String
    var frame: String

    // MARK: - Initializer

    init(id: UUID, path: String, frame: String = "") {
        self.id = id
        self.path = path
        self.frame = frame
    }
}
