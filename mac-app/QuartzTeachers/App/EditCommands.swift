import SwiftUI

/// The Edit menu's own item for the sidebar: changing a course's code.
///
/// It carries no keyboard shortcut, and that is deliberate. Return starts a
/// rename in the sidebar, but a bare Return as a menu key equivalent is
/// matched by AppKit before the key reaches the responder chain — it would
/// be taken away from every text field and default button in the window.
/// Finder's own Rename item has no key equivalent for exactly this reason,
/// and the sidebar handles the key itself instead.
struct EditCommands: View {

    // MARK: - Stored properties

    /// The window with focus, since each window has its own working folder
    /// and its own selection.
    @FocusedValue(\.workspace) var workspace: WorkspaceModel?

    // MARK: - Computed properties

    /// Why the item is dimmed, when it is dimmed for a reason worth saying.
    /// Nothing selected needs no explanation; a course mid-preview does.
    var unavailableReason: String? {
        guard let workspace else {
            return nil
        }
        if workspace.courseThatCanBeRenamed == nil {
            return nil
        }
        return workspace.renameIsUnavailableReason
    }

    // MARK: - Body

    var body: some View {
        Divider()

        Button("Rename Course") {
            workspace?.beginRenamingSelectedCourse()
        }
        .disabled(workspace?.courseThatCanBeRenamed == nil || unavailableReason != nil)

        // Dimmed alone says "no"; the line under it says what to do about
        // it — the shape the course's own menu already uses.
        if let unavailableReason {
            Text(unavailableReason)
        }
    }
}
