import AppKit

/// Where each section's assistant window was left, so it comes back there.
///
/// **Placement, not restoration.** The assistant window group is deliberately
/// `.restorationBehavior(.disabled)`: reopening it at launch would load a
/// model — gigabytes of a teacher's memory — before they had asked for one.
/// That decision stands. What is remembered here is only WHERE the window
/// goes when the teacher opens it themselves, which is the part they notice:
/// a window that reappears in the middle of the screen, over the section it
/// is meant to sit beside, has to be dragged back every single time.
///
/// **Per section, because that is how it is used.** A teacher works on one
/// section with the assistant beside its preview, and the two windows form a
/// layout they have arranged on purpose. Section 2's assistant may well
/// belong somewhere else entirely — a second monitor, the other half of the
/// screen. One shared position would mean arranging it again on every switch.
///
/// AppKit already does the saving. Naming a window's frame autosave puts the
/// frame in `UserDefaults` on every move and resize, and survives quit without
/// anything of ours running at the right moment — which matters, because the
/// moment a window closes is exactly when app code is least likely to get a
/// turn.
@MainActor
enum AssistWindowPlacement {

    // MARK: - Functions

    /// Where one section's assistant window was left, as a defaults key.
    ///
    /// Deliberately NOT an AppKit frame-autosave name. SwiftUI's `WindowGroup`
    /// assigns its own — `assistant-AppWindow-1`, from the group's id — and it
    /// wins: setting ours was silently replaced, so nothing was ever written
    /// under it and every window opened at the default place. SwiftUI's own
    /// key is also one key for ALL assistant windows, which is the wrong
    /// grain: this is per section on purpose.
    ///
    /// So the frame is kept here and applied by hand. Fighting a framework
    /// over ownership of a value is a fight to lose; keeping our own copy is
    /// not a fight at all.
    static func storageKey(courseCode: String, sectionNumber: Int) -> String {
        return "AssistantWindowFrame-\(courseCode.uppercased())-\(sectionNumber)"
    }

    /// The autosave name we no longer use, kept only so the old key can be
    /// read once by anyone who happens to have one.
    static func autosaveName(courseCode: String, sectionNumber: Int) -> String {
        return "AssistantWindow-\(courseCode.uppercased())-\(sectionNumber)"
    }

    /// Put this window back where that section's assistant was left.
    ///
    /// Applied with `setFrame` rather than through an autosave name, for the
    /// reason above. AppKit constrains the result to the visible screens, so a
    /// frame saved on a monitor that is no longer attached comes back on one
    /// that is rather than off the edge of the world.
    static func remember(
        _ window: NSWindow,
        courseCode: String,
        sectionNumber: Int,
        defaults: UserDefaults = UserDefaults.standard
    ) {
        let key: String = storageKey(courseCode: courseCode, sectionNumber: sectionNumber)
        guard let saved = defaults.string(forKey: key) else {
            return
        }
        let frame: NSRect = NSRectFromString(saved)
        if frame.width < 200 || frame.height < 200 {
            return
        }
        window.setFrame(frame, display: true)
    }

    /// Write down where the window is, now.
    ///
    /// Called when the window closes and when the app quits with it open —
    /// the two moments a teacher has just finished arranging things, and the
    /// two least likely to leave a framework's own lazy save a turn.
    static func save(
        _ window: NSWindow?,
        courseCode: String,
        sectionNumber: Int,
        defaults: UserDefaults = UserDefaults.standard
    ) {
        guard let window else {
            return
        }
        defaults.set(
            NSStringFromRect(window.frame),
            forKey: storageKey(courseCode: courseCode, sectionNumber: sectionNumber)
        )
    }
}
