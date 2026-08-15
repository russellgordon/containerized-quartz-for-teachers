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

    /// The autosave name for one section's assistant window.
    ///
    /// The course code is upper-cased so that a course reached by two
    /// differently-typed names — a teacher typing `ics3u` into a tool, the
    /// sidebar showing `ICS3U` — cannot end up with two remembered positions
    /// for one window.
    static func autosaveName(courseCode: String, sectionNumber: Int) -> String {
        return "AssistantWindow-\(courseCode.uppercased())-\(sectionNumber)"
    }

    /// Put this window where that section's assistant was last left, and keep
    /// it remembered from now on.
    ///
    /// The order is not arbitrary: the saved frame is applied FIRST, and the
    /// autosave name set after. Setting the name first invites AppKit to
    /// write the window's current — default, freshly-cascaded — frame under
    /// that name, which would quietly overwrite the position being restored
    /// with the one being replaced.
    static func remember(_ window: NSWindow, courseCode: String, sectionNumber: Int) {
        let name: String = autosaveName(courseCode: courseCode, sectionNumber: sectionNumber)
        window.setFrameUsingName(NSWindow.FrameAutosaveName(name))
        window.setFrameAutosaveName(NSWindow.FrameAutosaveName(name))
    }
}
