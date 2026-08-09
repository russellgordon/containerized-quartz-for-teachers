import Foundation

/// What is currently selected in the sidebar: a whole course (settings view)
/// or one section of a course (preview/deploy view).
enum SidebarSelection: Hashable {
    case course(String)
    case section(String, Int)
}
