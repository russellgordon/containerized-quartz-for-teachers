import Foundation

/// The value a window is presented for: which folder it is working in.
///
/// This is what makes per-window restoration work. Each window of the group
/// is bound to one of these, macOS encodes it into the window's restoration
/// state, and the window comes back with its own folder — the mechanism
/// SwiftUI actually provides for this, where `@SceneStorage` proved to share
/// one value across every window of the group.
///
/// The `id` keeps every value distinct: windows presented for equal values
/// are treated as the same window, and two fresh windows would otherwise
/// both be "the empty-path window".
struct WindowFolder: Codable, Hashable {

    // MARK: - Stored properties

    let id: UUID
    var path: String
}
