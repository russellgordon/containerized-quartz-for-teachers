import XCTest
@testable import QuartzTeachers

/// Plan mode is what makes a router that is sometimes wrong safe to hand a
/// teacher. Each rule here is a decision about how much to trust the model on
/// a given Mac, so each is pinned.
@MainActor
final class AssistPlanModeTests: XCTestCase {

    // MARK: - Functions

    private func makeDefaults() -> UserDefaults {
        let suite: String = "AssistPlanModeTests-\(UUID().uuidString)"
        let defaults: UserDefaults = UserDefaults(suiteName: suite)!
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suite)
        }
        return defaults
    }

    // MARK: - The small tier

    /// **Both assistants behave identically.** Same default, same count, same
    /// mention, same switch.
    ///
    /// The smaller one used to refuse to be turned off and was never told the
    /// setting existed, on the reasoning that one request in five going wrong
    /// is not a rate at which anybody should stop reading. That withheld a
    /// setting from exactly the machine where knowing about it matters most.
    /// The measured number is put in front of the teacher as a caution
    /// instead, which respects the measurement and the person.
    func testBothAssistantsFollowTheSameRules() {
        for tier in AssistModelTier.allCases {
            let mode: AssistPlanMode = AssistPlanMode(
                tier: tier, settings: AppSettings(defaults: makeDefaults())
            )
            XCTAssertTrue(mode.isOn, "\(tier) should ask by default")

            for _ in 0..<(AssistPlanMode.plansBeforeMentioningTheSetting - 1) {
                mode.recordAccepted()
            }
            XCTAssertFalse(mode.shouldOfferToStop, "\(tier): fourteen is not fifteen")

            mode.recordAccepted()
            XCTAssertTrue(mode.shouldOfferToStop,
                          "\(tier) was never told the setting exists")

            mode.stopAsking()
            XCTAssertFalse(mode.isOn, "\(tier) refused to be turned off")
        }
    }

    /// An answer given in Settings is honoured on both assistants — the
    /// teacher decides, whichever one is running.
    func testTheSettingIsHonouredOnBothAssistants() {
        let defaults: UserDefaults = makeDefaults()
        defaults.set(false, forKey: AppSettings.assistantAsksBeforeChangingKey)
        XCTAssertFalse(AssistPlanMode(tier: .small, settings: AppSettings(defaults: defaults)).isOn)
        XCTAssertFalse(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn)
    }

    // MARK: - The large tier

    func testPlansAreShownUntilATeacherSaysOtherwise() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: makeDefaults()))
        XCTAssertTrue(mode.isOn, "Plans are shown until a teacher says otherwise")
    }

    /// One sentence for both assistants, and it names where to change it.
    func testTheExplanationIsTheSameOnBothAndPointsAtTheSetting() {
        for tier in AssistModelTier.allCases {
            let mode: AssistPlanMode = AssistPlanMode(
                tier: tier, settings: AppSettings(defaults: makeDefaults())
            )
            XCTAssertTrue(mode.explanation.contains("Settings"), "\(tier): \(mode.explanation)")
            XCTAssertFalse(mode.explanation.contains("always shows"),
                           "\(tier) still claims it always shows plans: \(mode.explanation)")
        }
    }

    /// Fifteen, and only once — the mention is about DISCOVERABILITY, and a
    /// suggestion declined is an answer.
    func testTheSettingIsMentionedAfterFifteenAndOnlyOnce() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: makeDefaults()))

        for _ in 0..<(AssistPlanMode.plansBeforeMentioningTheSetting - 1) {
            mode.recordAccepted()
        }
        XCTAssertFalse(mode.shouldOfferToStop, "Fourteen is not yet fifteen")

        mode.recordAccepted()
        XCTAssertTrue(mode.shouldOfferToStop)

        mode.keepAsking()
        XCTAssertTrue(mode.isOn)
        XCTAssertFalse(mode.shouldOfferToStop, "Declining once means not being pestered again")
    }

    /// The count is APP-WIDE and outlives the conversation it was earned in.
    ///
    /// It used to reset with every window, so a teacher working in short
    /// bursts could accept a hundred plans across twenty conversations and
    /// never be told the setting existed.
    func testThePlanCountIsAppWideAndSurvivesANewConversation() {
        let defaults: UserDefaults = makeDefaults()
        let first: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults))
        for _ in 0..<10 {
            first.recordAccepted()
        }

        let second: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults))
        XCTAssertEqual(second.plansAccepted, 10, "The count reset when the window did")
        for _ in 0..<5 {
            second.recordAccepted()
        }
        XCTAssertTrue(second.shouldOfferToStop, "Ten plus five is fifteen, across two windows")
    }

    /// Once told, never told again — in any window, ever.
    func testOnceMentionedItIsNeverMentionedAgain() {
        let defaults: UserDefaults = makeDefaults()
        let first: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults))
        for _ in 0..<AssistPlanMode.plansBeforeMentioningTheSetting {
            first.recordAccepted()
        }
        XCTAssertTrue(first.shouldOfferToStop)
        first.noteOfferShown()

        let later: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults))
        for _ in 0..<50 {
            later.recordAccepted()
        }
        XCTAssertFalse(later.shouldOfferToStop,
                       "A teacher was told twice about the same setting")
    }

    /// A Cancel does not undo a plan already agreed to. The count measures how
    /// much of the assistant's work this teacher has READ, and a Cancel is
    /// evidence of reading rather than evidence against it.
    func testACancelDoesNotUndoPlansAlreadyAgreedTo() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: makeDefaults()))
        for _ in 0..<4 {
            mode.recordAccepted()
        }
        mode.recordCancelled()
        XCTAssertEqual(mode.plansAccepted, 4)
    }

    /// The answer outlives the window it was given in.
    func testTurningItOffIsRemembered() {
        let defaults: UserDefaults = makeDefaults()
        let first: AssistPlanMode = AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults))
        first.stopAsking()
        XCTAssertFalse(first.isOn)

        XCTAssertFalse(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn,
                       "A new conversation keeps the teacher's answer")

        first.keepAsking()
        XCTAssertTrue(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn,
                      "And keeps it when they change their mind back")
    }

    // MARK: - What plan mode gates

    /// Reads answer immediately; writes wait. Gating reads would make every
    /// question two clicks and train people to press Go without reading.
    func testOnlyWritesHaveAPlanTwin() {
        for tool in AssistToolRunner.tools {
            if tool.readOnly {
                XCTAssertNil(tool.planTwinName, "\(tool.name) changes nothing, so it must not be gated")
            } else {
                XCTAssertNotNil(tool.planTwinName, "\(tool.name) changes pages and must be showable first")
            }
        }
    }

    /// Every write is either showable first or is its own reversal — nothing
    /// in between.
    ///
    /// This test found a real bug: `planTwinName` named a twin for every
    /// write, including four that have none, so plan mode would have asked
    /// the runner for `plan_rebuild_preview`, been told there is no such
    /// tool, and shown the teacher an error where their plan should be.
    func testEveryWriteIsEitherShowableOrItsOwnReversal() {
        // These four have nothing to plan. Listed here so that adding a
        // fifth is a decision somebody makes on purpose.
        let ownReversal: Set<String> = [
            "rebuild_preview",        // changes no page
            "undo_last_change",       // IS the undo
            "deploy_section",         // waits on its own button already
            "cancel_scheduled_deploy" // remedied by scheduling it again
        ]

        var names: Set<String> = []
        for tool in AssistToolRunner.tools {
            names.insert(tool.name)
        }

        for tool in AssistToolRunner.tools where !tool.readOnly {
            if ownReversal.contains(tool.name) {
                continue
            }
            guard let twin = tool.planTwinName else {
                return XCTFail("\(tool.name) changes pages but cannot be shown first")
            }
            XCTAssertTrue(names.contains(twin),
                          "\(tool.name) would be gated behind \(twin), which does not exist")
        }
    }

    /// And the four really are the only ones without a twin, so the list
    /// above cannot quietly fall out of step with the surface.
    func testNoOtherWriteIsMissingItsTwin() {
        var names: Set<String> = []
        for tool in AssistToolRunner.tools {
            names.insert(tool.name)
        }
        var missing: [String] = []
        for tool in AssistToolRunner.tools where !tool.readOnly {
            guard let twin = tool.planTwinName, names.contains(twin) else {
                missing.append(tool.name)
                continue
            }
        }
        XCTAssertEqual(
            Set(missing),
            ["rebuild_preview", "undo_last_change", "deploy_section", "cancel_scheduled_deploy"],
            "The set of writes with no plan twin changed — decide deliberately what plan mode does with the new one"
        )
    }

    /// The one irregular pair, pinned so nobody "tidies" it.
    func testScheduleDeployHasItsIrregularTwin() {
        for tool in AssistToolRunner.tools where tool.name == "schedule_deploy" {
            XCTAssertEqual(tool.planTwinName, "plan_scheduled_deploy")
        }
    }
}
