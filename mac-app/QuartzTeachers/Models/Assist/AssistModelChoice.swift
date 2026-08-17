import Foundation

/// Which assistant the TEACHER has asked for, as distinct from which one this
/// Mac would pick on its own.
///
/// Until this existed, `AssistHardwareBudget.tier` was the whole answer: the
/// app read the memory, picked a rung, and the teacher never learned there had
/// been a decision. That is the right default and it is a poor only-option,
/// for two reasons that arrive from opposite directions.
///
/// A teacher on a 16 GB Mac who also keeps a site building, a browser full of
/// tabs and Obsidian open may want the smaller one back — the automatic
/// choice sizes itself to the machine, not to what else is on it, and only
/// the person sitting there knows the difference. And a teacher on an 8 GB
/// Mac who has just closed everything else may want the better one for an
/// afternoon of planning. Neither can be inferred from `sysctl`.
///
/// **`automatic` is preserved as a distinct value rather than being resolved
/// once and written down.** If it stored "the larger assistant" the day the
/// teacher first opened the panel, then a rule change — or the 8 GB
/// reconsideration written up in `AssistModelTier.forPhysicalMemory` — would
/// reach every Mac EXCEPT the ones whose teacher had opened Settings, which
/// is precisely backwards. Storing the intent means "choose for me" keeps
/// meaning choose for me.
nonisolated enum AssistModelChoice: String, CaseIterable, Sendable {

    // MARK: - Cases

    /// Let the app size the assistant to this Mac — the factory setting, and
    /// what every Mac did before the panel existed.
    case automatic

    /// The teacher has asked for the smaller one, whatever the machine is.
    case smaller

    /// The teacher has asked for the larger one, whatever the machine is.
    case larger

    // MARK: - Computed properties

    /// The label beside the radio button.
    var label: String {
        switch self {
        case .automatic: return "Choose for me"
        case .smaller: return AssistModelTier.small.choiceLabel
        case .larger: return AssistModelTier.large.choiceLabel
        }
    }

    /// The rung this names outright, or nil for the one that decides later.
    var namedTier: AssistModelTier? {
        switch self {
        case .automatic: return nil
        case .smaller: return .small
        case .larger: return .large
        }
    }

    // MARK: - Functions

    /// The choice that names a tier, used to show which one `automatic`
    /// currently lands on without changing what is stored.
    static func naming(_ tier: AssistModelTier) -> AssistModelChoice {
        switch tier {
        case .small: return .smaller
        case .large: return .larger
        }
    }

    /// Which assistant actually runs on this Mac, given this choice.
    func resolved(for budget: AssistHardwareBudget) -> AssistModelTier {
        guard let named = namedTier else {
            return budget.tier
        }
        return named
    }

    /// The sentence under the label.
    ///
    /// `automatic` describes the machine and the answer it produced, because
    /// "choose for me" with nothing under it leaves a teacher unable to tell
    /// whether the setting is doing anything. The other two describe what the
    /// choice costs — see `AssistModelTier.sizeGuidance`.
    func detail(for budget: AssistHardwareBudget) -> String {
        guard let named = namedTier else {
            let chosen: AssistModelTier = budget.tier
            return "This Mac has \(budget.memoryDescription) of memory, "
                 + "so Plantoir uses \(chosen.displayName)."
        }
        return named.sizeGuidance
    }

    /// The caution shown when this choice would take more of the Mac than the
    /// app would ever take on its own, or nil when it is comfortable.
    ///
    /// It is a caution rather than a block, and that is a decision: the option
    /// stays selectable. A teacher who has just quit everything else knows
    /// something `sysctl` does not, and a greyed-out row with a reason beside
    /// it gives them no way to act on what they know. What they are owed is
    /// the numbers — theirs and its — in one sentence, so the choice is
    /// informed rather than prevented.
    ///
    /// Only ever shown for a HAND-PICKED choice: `automatic` cannot produce
    /// one, because the ladder is held to the same third-of-memory line.
    func caution(for budget: AssistHardwareBudget) -> String? {
        guard let named = namedTier else {
            return nil
        }
        if budget.isComfortable(with: named) {
            return nil
        }
        return "This Mac has \(budget.memoryDescription) of memory, and "
             + "\(named.displayName) needs about \(named.memoryDescription) while it is "
             + "working — so other things you have open may slow down. You can still "
             + "choose it, and you can come back and change it."
    }
}
