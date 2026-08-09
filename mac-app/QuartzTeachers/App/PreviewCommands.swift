import SwiftUI

/// Menu-bar commands for the embedded website preview.
///
/// The shortcuts live on MENU items rather than toolbar buttons because
/// a focused web view swallows key events before SwiftUI toolbar
/// shortcuts see them — menu key equivalents always work. (Back and
/// Forward would partly work anyway, since WebKit handles ⌘[ and ⌘]
/// natively, but Reload would not.)
struct PreviewCommands: Commands {

    // MARK: - Stored properties

    @FocusedValue(\.previewController) var previewController

    // MARK: - Body

    var body: some Commands {
        CommandMenu("Preview") {
            Button("Back") {
                previewController?.goBack()
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(previewController?.canGoBack != true)

            Button("Forward") {
                previewController?.goForward()
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(previewController?.canGoForward != true)

            Divider()

            Button("Reload Page") {
                previewController?.reload()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(previewController == nil)
        }
    }
}
