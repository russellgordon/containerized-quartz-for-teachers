import AppKit
import SwiftUI

/// Answers Return while the courses sidebar has keyboard focus — which
/// SwiftUI cannot be asked to do here.
///
/// **Why this exists rather than `.onKeyPress(.return)` on the `List`.** That
/// modifier is never called. The list is an `NSOutlineView` underneath, and
/// it IS the thing with keyboard focus — confirmed through the accessibility
/// API on a running app, where the focused element is the outline carrying
/// the sidebar's own identifier — but an outline view answers Return itself
/// instead of passing it on, so the SwiftUI modifier sits below the place the
/// event stops. A local key monitor sees the event first.
///
/// **Why not a keyboard shortcut on the menu item**, which would be a line of
/// code. A bare Return as a menu key equivalent is matched by AppKit before
/// the key reaches whatever has focus, so it would take Return away from
/// every text field and default button in the window — including the rename
/// field this very feature opens. Finder's own Rename item carries no key
/// equivalent for the same reason.
///
/// It is deliberately narrow. It answers only a bare Return or keypad Enter,
/// only in the window it was installed for, and only while the thing with
/// focus is the courses list and is not a text field. Everywhere else the
/// event is handed straight back untouched.
@MainActor
final class SidebarReturnKey {

    // MARK: - Stored properties

    private var monitor: Any?

    /// The window this belongs to. A local monitor is APP-wide, so without
    /// this every open window would answer one press of Return — and rename
    /// a course in a folder the teacher is not looking at.
    var window: NSWindow?

    // MARK: - Functions

    /// Puts keyboard focus in the courses list.
    ///
    /// Through AppKit, because SwiftUI will not do it. The course settings
    /// form's first text field takes the window's focus whenever a course is
    /// selected and keeps it — measured on a running app through the
    /// accessibility API, where the focused element stays `courseNameField`
    /// no matter how the list asks, `.focused()` and a deferred `.focused()`
    /// included. Nothing in the app claims that focus; it is SwiftUI's own
    /// initial focus, re-established every time the detail pane is rebuilt.
    ///
    /// Without this the sidebar can never hold the keyboard at all: Return
    /// goes to the settings form, and so would the arrow keys.
    func focusTheCoursesList() {
        guard let window else {
            return
        }
        guard let list = SidebarReturnKey.coursesList(in: window) else {
            return
        }
        if window.firstResponder === list {
            return
        }
        window.makeFirstResponder(list)
    }

    /// The courses list's own view, found by the identifier the sidebar
    /// gives it.
    static func coursesList(in window: NSWindow) -> NSView? {
        guard let root = window.contentView else {
            return nil
        }
        if let named = SidebarReturnKey.view(in: root, identified: SidebarView.listIdentifier) {
            return named
        }
        // A fallback rather than a guess: the sidebar is the only outline in
        // the window, and an identifier SwiftUI declined to pass through to
        // the view should not cost the teacher the feature.
        return SidebarReturnKey.firstOutlineView(in: root)
    }

    static func view(in root: NSView, identified identifier: String) -> NSView? {
        if root.accessibilityIdentifier() == identifier {
            return root
        }
        for subview in root.subviews {
            if let found = SidebarReturnKey.view(in: subview, identified: identifier) {
                return found
            }
        }
        return nil
    }

    static func firstOutlineView(in root: NSView) -> NSView? {
        if root is NSOutlineView {
            return root
        }
        for subview in root.subviews {
            if let found = SidebarReturnKey.firstOutlineView(in: subview) {
                return found
            }
        }
        return nil
    }

    /// Starts watching. `action` returns true when it has dealt with the
    /// key, which swallows it; false hands it on untouched.
    func start(action: @escaping @MainActor () -> Bool) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // A Bool comes back out rather than the event itself: an NSEvent
            // is not `Sendable`, so returning one across the isolation check
            // does not compile.
            let wasDealtWith: Bool = MainActor.assumeIsolated {
                if self.answers(event) {
                    return action()
                }
                return false
            }
            if wasDealtWith {
                return nil
            }
            return event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    /// Whether this key press is the one being watched for.
    func answers(_ event: NSEvent) -> Bool {
        if !SidebarReturnKey.isPlainReturn(event) {
            return false
        }
        guard let window else {
            return false
        }
        if event.window !== window {
            return false
        }
        guard let focused = window.firstResponder as? NSView else {
            return false
        }
        // A field editor is a subview of the very row being edited, so its
        // ancestors include the list. Typing Return into the rename field
        // must reach the field, not open a second one.
        if focused is NSText {
            return false
        }
        guard let list = SidebarReturnKey.coursesList(in: window) else {
            return false
        }
        return focused === list || focused.isDescendant(of: list)
    }

    /// Return or keypad Enter with nothing held down. Shift-Return and
    /// ⌘-Return are somebody else's business.
    static func isPlainReturn(_ event: NSEvent) -> Bool {
        let returnKey: UInt16 = 36
        let keypadEnter: UInt16 = 76
        if event.keyCode != returnKey && event.keyCode != keypadEnter {
            return false
        }
        let held: NSEvent.ModifierFlags = event.modifierFlags.intersection([
            .command, .option, .control, .shift,
        ])
        return held.isEmpty
    }

}
