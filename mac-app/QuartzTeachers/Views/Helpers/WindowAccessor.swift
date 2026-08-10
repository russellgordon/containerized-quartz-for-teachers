import AppKit
import SwiftUI

/// Hands the hosting `NSWindow` to SwiftUI content once it is on screen.
///
/// The window is not available when a view appears — only once the view is
/// installed in a window — so this waits for it, briefly and off the layout
/// path.
struct WindowAccessor: NSViewRepresentable {

    // MARK: - Stored properties

    let onWindow: (NSWindow) -> Void

    // MARK: - Functions

    func makeNSView(context: Context) -> NSView {
        let view: NSView = NSView()
        WindowAccessor.deliverWindow(of: view, attemptsLeft: 20, onWindow: onWindow)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }

    /// Polls until the view has been installed in its window.
    static func deliverWindow(of view: NSView, attemptsLeft: Int, onWindow: @escaping (NSWindow) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak view] in
            guard let view else {
                return
            }
            if let window = view.window {
                onWindow(window)
                return
            }
            if attemptsLeft > 0 {
                deliverWindow(of: view, attemptsLeft: attemptsLeft - 1, onWindow: onWindow)
            }
        }
    }
}
