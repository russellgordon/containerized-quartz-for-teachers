import SwiftUI

/// Sizes shared by the window's edges, so the sidebar's footer and the
/// path bar below the content are the same height and their dividers line
/// up across the window.
enum WindowChrome {

    // MARK: - Stored properties

    /// How tall a footer's contents are at the standard text size — enough
    /// for a 24pt button with room around it.
    static let footerHeight: CGFloat = 34

    /// The sidebar's footer stops short of the window's bottom edge, because
    /// the split view insets the sidebar; the path bar opposite it sits
    /// flush. The path bar therefore has to be this much taller for the two
    /// dividers to meet on one line. Measured from a screenshot at the
    /// standard text size — 10 pixels at 1.41x.
    static let sidebarBottomInset: CGFloat = 7

    /// The height of the path bar strip, divider to window edge.
    static let pathBarHeight: CGFloat = footerHeight + sidebarBottomInset
}
