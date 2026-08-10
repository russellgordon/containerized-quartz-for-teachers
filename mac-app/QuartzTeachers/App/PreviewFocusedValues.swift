import SwiftUI

extension FocusedValues {

    /// The web preview controller of the frontmost section view, so
    /// menu commands can drive it.
    @Entry var previewController: WebPreviewController?

    /// The working folder of the window that currently has focus, so the
    /// File menu acts on that window rather than on a single shared one.
    @Entry var workspace: WorkspaceModel?
}
