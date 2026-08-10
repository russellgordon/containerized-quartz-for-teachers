import SwiftUI

/// File-menu items that act on the window with focus, since each window has
/// its own working folder.
struct WorkspaceCommands: View {

    // MARK: - Stored properties

    @FocusedValue(\.workspace) var workspace: WorkspaceModel?

    // MARK: - Body

    var body: some View {
        Button("Change Working Folder…") {
            workspace?.isChoosingWorkspace = true
        }
        .disabled(workspace == nil)

        Button("Restore from Archive…") {
            workspace?.restoreRequest = workspace?.selectedArchivedItem
        }
        .disabled(workspace?.selectedArchivedItem == nil)

        Button("Reload Courses") {
            workspace?.reloadCourses()
        }
        .keyboardShortcut("r", modifiers: [.command, .shift])
        .disabled(workspace == nil)
    }
}
