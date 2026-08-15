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

    /// An 8 GB Mac runs the model that gets about one request in five wrong.
    /// That is not a rate at which anyone should be offered a "stop checking"
    /// button, so the offer does not exist there.
    func testTheSmallTierAlwaysShowsPlans() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .small, defaults: makeDefaults())
        XCTAssertTrue(mode.isOn)
        XCTAssertFalse(mode.mayBeTurnedOff)

        for _ in 0..<20 {
            mode.recordAccepted()
        }
        XCTAssertFalse(mode.shouldOfferToStop, "The smaller model must never offer to stop checking")

        // Even asked directly, it declines — so a future caller cannot turn
        // it off by accident.
        mode.stopAsking()
        XCTAssertTrue(mode.isOn, "Plan mode must stay on for the smaller model whatever it is asked")
    }

    /// A teacher who turned plan mode off on a capable Mac, then opened a
    /// course on an 8 GB one, must not inherit that answer.
    func testTheSmallTierIgnoresARememberedChoice() {
        let defaults: UserDefaults = makeDefaults()
        defaults.set(true, forKey: "AssistPlanModeTurnedOff")
        XCTAssertTrue(AssistPlanMode(tier: .small, defaults: defaults).isOn)
    }

    // MARK: - The large tier

    func testTheLargeTierStartsOnAndMayBeTurnedOff() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .large, defaults: makeDefaults())
        XCTAssertTrue(mode.isOn, "Plans are shown until a teacher says otherwise")
        XCTAssertTrue(mode.mayBeTurnedOff)
    }

    /// Five in a row, and only once — trust is earned rather than assumed,
    /// and a teacher who says "keep checking" is not asked again.
    func testTheOfferArrivesAfterFiveAndOnlyOnce() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .large, defaults: makeDefaults())

        for _ in 0..<4 {
            mode.recordAccepted()
        }
        XCTAssertFalse(mode.shouldOfferToStop, "Four is not yet a pattern")

        mode.recordAccepted()
        XCTAssertTrue(mode.shouldOfferToStop)

        mode.keepAsking()
        XCTAssertTrue(mode.isOn)
        XCTAssertFalse(mode.shouldOfferToStop, "Declining once means not being pestered again")
    }

    /// A Cancel is the gate doing its job. Somebody who has just stopped the
    /// assistant doing the wrong thing must not then be asked whether they
    /// would like it to stop asking.
    func testACancelResetsTheRun() {
        let mode: AssistPlanMode = AssistPlanMode(tier: .large, defaults: makeDefaults())
        for _ in 0..<4 {
            mode.recordAccepted()
        }
        mode.recordCancelled()
        XCTAssertEqual(mode.acceptedInARow, 0)

        mode.recordAccepted()
        XCTAssertFalse(mode.shouldOfferToStop, "The run starts again after a Cancel")
    }

    /// The answer outlives the window it was given in.
    func testTurningItOffIsRemembered() {
        let defaults: UserDefaults = makeDefaults()
        let first: AssistPlanMode = AssistPlanMode(tier: .large, defaults: defaults)
        first.stopAsking()
        XCTAssertFalse(first.isOn)

        XCTAssertFalse(AssistPlanMode(tier: .large, defaults: defaults).isOn,
                       "A new conversation keeps the teacher's answer")

        first.keepAsking()
        XCTAssertTrue(AssistPlanMode(tier: .large, defaults: defaults).isOn,
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
