import Foundation

/// Whether the assistant shows what it is about to do and waits for a button.
///
/// **Why this exists at all.** The local model is a router, and routers are
/// wrong sometimes: measured, the small model puts about one request in five
/// on the wrong tool. Plan mode turns that from a thing that happens to a
/// thing a teacher declines — the assistant says what it understood, in
/// words, and nothing happens until they press Go.
///
/// **Why it is not simply always on.** A gate in front of every action
/// teaches people to click through gates. A teacher who has pressed Go on
/// forty correct plans is not reading the forty-first, and at that point the
/// gate is costing attention without buying safety. So on machines whose
/// model has earned it, the assistant offers to stop asking.
///
/// **Why the two tiers differ.** It is not a preference, it is the
/// measurement: the model an 8 GB Mac runs routes at 79%, and the one a 16 GB
/// Mac runs routes at 100% on the same probes. One in five wrong is a rate at
/// which a teacher should be reading every plan. Perfect on 180 trials is a
/// rate at which insisting they read is condescending.
@Observable
@MainActor
final class AssistPlanMode {

    // MARK: - Stored properties

    /// The model this Mac runs.
    ///
    /// No longer decides anything about the gate. It used to: the smaller
    /// assistant refused to be turned off and was never told the setting
    /// existed, on the reasoning that one request in five going wrong is not a
    /// rate at which anybody should stop reading. But whether to confirm is
    /// the teacher's decision on their own Mac, and a setting nobody is told
    /// about might as well not exist — least of all on the machine where it
    /// matters most. The measured number is put in front of them instead, as a
    /// caution in Settings, which respects both the measurement and the
    /// person.
    let tier: AssistModelTier

    /// Whether plans are being shown right now.
    private(set) var isOn: Bool

    /// Whether the offer has already been made in THIS window, on top of the
    /// app-wide "once, ever" rule — so it cannot appear twice in one sitting.
    private(set) var hasOfferedToStop: Bool = false

    /// Where the teacher's answer is remembered between conversations.
    /// Where the teacher's answers live — shared with the settings panel, so
    /// the switch there and the gate here can never disagree.
    private let settings: AppSettings

    // MARK: - Computed properties

    /// How many plans this teacher has agreed to, app-wide and for good.
    var plansAccepted: Int {
        return settings.plansAccepted
    }

    /// After this many, the assistant mentions that the setting exists.
    ///
    /// Fifteen, app-wide, counted across every conversation and every course.
    /// It is not a threshold for TRUST — the teacher decides that — it is a
    /// threshold for DISCOVERABILITY: after fifteen plans read and agreed to,
    /// somebody has enough of a feel for the assistant to judge whether they
    /// want the gate, and a switch nobody knows about might as well not exist.
    static let plansBeforeMentioningTheSetting: Int = 15

    /// Whether to mention the setting now.
    ///
    /// **Once, ever.** A suggestion declined is an answer, and asking again is
    /// how a helpful mention becomes nagging. `hasOfferedToStop` guards the
    /// window; `settings.hasBeenToldAboutTheSetting` guards the rest of time.
    var shouldOfferToStop: Bool {
        return isOn
            && !hasOfferedToStop
            && !settings.hasBeenToldAboutTheSetting
            && plansAccepted >= AssistPlanMode.plansBeforeMentioningTheSetting
    }

    /// What the teacher is told about why plans are being shown.
    ///
    /// One sentence for both assistants. It used to say something different on
    /// the smaller one — "it always shows what it is about to do first" — which
    /// stopped being true the day the switch arrived, and a line describing
    /// what a feature used to do is worse than no line.
    var explanation: String {
        return "The assistant shows what it is about to do before doing it. "
             + "You can change that in Plantoir ▸ Settings."
    }

    // MARK: - Initializer

    /// Takes the settings OBJECT rather than a defaults store, so the gate and
    /// the switch in Settings are literally the same value in memory.
    ///
    /// Building its own `AppSettings` from the same store looked equivalent and
    /// is not: each instance caches the answer it read at construction, so a
    /// change made through one was invisible to the other until something
    /// reloaded. In the app both would have been `AppSettings.shared` and it
    /// would have worked by luck.
    init(tier: AssistModelTier, settings: AppSettings = AppSettings.shared) {
        self.tier = tier
        self.settings = settings
        // On by default, always. A teacher who has turned it off on a capable
        // Mac keeps that answer; everybody else starts with plans shown, and
        // the smaller tier cannot turn it off at all.
        // One stored answer, shared with the settings panel. It used to live
        // here under a key of its own, which was fine while this was the only
        // way to change it and became a way for two switches to disagree the
        // moment Settings gained one.
        isOn = settings.assistantAsksBeforeChanging
    }

    // MARK: - Functions

    /// The teacher pressed Go.
    ///
    /// Counted app-wide and never reset. A Cancel used to zero it, on the
    /// reasoning that somebody who has just stopped the assistant should not
    /// then be asked to trust it — but the count now measures how much of the
    /// assistant's work this teacher has READ, which a Cancel is evidence of
    /// rather than evidence against.
    func recordAccepted() {
        settings.plansAccepted += 1
    }

    /// The teacher pressed Cancel — the gate just did its job.
    func recordCancelled() {
        // Nothing to undo: the count is of plans agreed to, and this was not
        // one. Kept as a call site so the two answers stay visible together.
    }

    /// The teacher took the offer to stop being asked.
    func stopAsking() {
        isOn = false
        hasOfferedToStop = true
        settings.hasBeenToldAboutTheSetting = true
        settings.assistantAsksBeforeChanging = false
    }

    /// The teacher declined the offer, or wants plans back.
    func keepAsking() {
        isOn = true
        hasOfferedToStop = true
        settings.hasBeenToldAboutTheSetting = true
        settings.assistantAsksBeforeChanging = true
    }

    /// Follow the setting, which the teacher may have changed in Settings
    /// while this window was open.
    ///
    /// Read at the start of every turn rather than only at construction: the
    /// settings window and the assistant are two windows on one screen, and a
    /// teacher who turns confirmation off expects the next thing they ask to
    /// go straight through — not the one after they have closed and reopened
    /// the conversation.
    func followTheSetting() {
        isOn = settings.assistantAsksBeforeChanging
    }

    /// The offer was shown; do not show it again, in this window or ever.
    func noteOfferShown() {
        hasOfferedToStop = true
        settings.hasBeenToldAboutTheSetting = true
    }

}
