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
        // A view that speaks up the INSTANT it is put into a window, rather
        // than a plain view polled for one.
        //
        // The difference is visible. Polling starts fifty milliseconds later,
        // by which time the window is on screen — so anything that moves it,
        // such as putting a remembered window back where it was left, happens
        // in front of the teacher: the window appears in the wrong place and
        // snaps. `viewDidMoveToWindow` is called as the view joins the window,
        // before it is ordered front, so the same move is invisible.
        //
        // The poll stays as a fallback for anything installed into a view
        // hierarchy that is not yet in a window.
        let view: WindowReadingView = WindowReadingView()
        view.onWindow = onWindow
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
            // Already handed over the moment it was installed.
            if let reader = view as? WindowReadingView, reader.hasReportedWindow {
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

/// An `NSView` that hands over its window the moment it has one.
private final class WindowReadingView: NSView {

    // MARK: - Stored properties

    var onWindow: ((NSWindow) -> Void)?

    /// Handed over once. Both this and the poll can fire, and whatever is
    /// being done with the window is rarely safe to do twice.
    private(set) var hasReportedWindow: Bool = false

    // MARK: - Functions

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !hasReportedWindow, let window else {
            return
        }
        hasReportedWindow = true
        onWindow?(window)
    }
}
