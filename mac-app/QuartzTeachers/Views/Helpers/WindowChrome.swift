import SwiftUI

/// Sizes shared by the window's edges, so the sidebar's footer and the
/// path bar below the content are the same height and their dividers line
/// up across the window.
enum WindowChrome {

    // MARK: - Stored properties

    /// How tall a footer is at the standard text size. Both footers use it,
    /// which is what keeps the two horizontal rules on one line.
    static let footerHeight: CGFloat = 34
}
