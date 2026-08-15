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

    /// The model this Mac runs, which decides whether turning it off is even
    /// offered.
    let tier: AssistModelTier

    /// Whether plans are being shown right now.
    private(set) var isOn: Bool

    /// Plans accepted in a row, without a Cancel.
    ///
    /// Reset by a Cancel rather than merely paused: a teacher who has just
    /// stopped the assistant doing the wrong thing should not then be asked
    /// whether they would like it to stop asking.
    private(set) var acceptedInARow: Int = 0

    /// Whether the offer to stop asking has already been made.
    private(set) var hasOfferedToStop: Bool = false

    /// Where the teacher's answer is remembered between conversations.
    private let defaults: UserDefaults

    // MARK: - Computed properties

    /// Whether this Mac's model is good enough to be trusted unattended.
    ///
    /// Only the larger tier. The small model's 79% is not a number to hand
    /// somebody a "stop asking me" button for.
    var mayBeTurnedOff: Bool {
        return tier == .large
    }

    /// Whether to put the "stop asking" offer in front of the teacher now.
    ///
    /// Five in a row, once. Five is enough to have seen it get the same kind
    /// of request right repeatedly, and the offer arrives while that is fresh
    /// rather than months later in a settings pane nobody opens.
    var shouldOfferToStop: Bool {
        return mayBeTurnedOff && isOn && !hasOfferedToStop && acceptedInARow >= 5
    }

    /// What the teacher is told about why plans are being shown.
    var explanation: String {
        if mayBeTurnedOff {
            return "The assistant shows what it is about to do before doing it."
        }
        return "This Mac runs the smaller assistant, which gets about one request "
             + "in five wrong, so it always shows what it is about to do first."
    }

    // MARK: - Initializer

    init(tier: AssistModelTier, defaults: UserDefaults = UserDefaults.standard) {
        self.tier = tier
        self.defaults = defaults
        // On by default, always. A teacher who has turned it off on a capable
        // Mac keeps that answer; everybody else starts with plans shown, and
        // the smaller tier cannot turn it off at all.
        if tier == .large, defaults.bool(forKey: AssistPlanMode.turnedOffKey) {
            isOn = false
        } else {
            isOn = true
        }
    }

    // MARK: - Functions

    /// The teacher pressed Go.
    func recordAccepted() {
        acceptedInARow += 1
    }

    /// The teacher pressed Cancel — the gate just did its job.
    func recordCancelled() {
        acceptedInARow = 0
    }

    /// The teacher took the offer to stop being asked.
    func stopAsking() {
        guard mayBeTurnedOff else {
            return
        }
        isOn = false
        hasOfferedToStop = true
        defaults.set(true, forKey: AssistPlanMode.turnedOffKey)
    }

    /// The teacher declined the offer, or wants plans back.
    func keepAsking() {
        isOn = true
        hasOfferedToStop = true
        defaults.set(false, forKey: AssistPlanMode.turnedOffKey)
    }

    /// The offer was shown; do not show it again unprompted.
    func noteOfferShown() {
        hasOfferedToStop = true
    }

    // MARK: - Stored keys

    private static let turnedOffKey: String = "AssistPlanModeTurnedOff"
}
