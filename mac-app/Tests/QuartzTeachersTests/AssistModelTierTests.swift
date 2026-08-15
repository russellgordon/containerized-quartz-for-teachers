import XCTest
@testable import QuartzTeachers

/// The tiering rule decides how much of a teacher's Mac the assistant takes,
/// so the sizes it lands on are worth pinning: getting this wrong does not
/// crash anything, it just makes the machine feel seized while a class is
/// being prepared.
final class AssistModelTierTests: XCTestCase {

    // MARK: - Functions

    private func budget(gigabytes: Int64, cores: Int, performanceCores: Int) -> AssistHardwareBudget {
        return AssistHardwareBudget(
            physicalMemoryBytes: gigabytes * 1_073_741_824,
            coreCount: cores,
            performanceCoreCount: performanceCores
        )
    }

    /// An 8 GB Mac keeps the small model. Colima takes 4 GB of that machine
    /// on its own, so this is the one rung that must not drift upwards.
    func testAnEightGigabyteMacGetsTheSmallModel() {
        XCTAssertEqual(budget(gigabytes: 8, cores: 8, performanceCores: 4).tier, .small)
    }

    /// 16 GB and up gets the 7B — the only model measured free of polarity
    /// inversions AND accurate (94% against the 1.5B's 81%).
    func testSixteenGigabytesAndUpGetsTheLargeModel() {
        XCTAssertEqual(budget(gigabytes: 16, cores: 8, performanceCores: 4).tier, .large)
        XCTAssertEqual(budget(gigabytes: 32, cores: 12, performanceCores: 8).tier, .large)
        XCTAssertEqual(budget(gigabytes: 48, cores: 12, performanceCores: 8).tier, .large)
        XCTAssertEqual(budget(gigabytes: 128, cores: 24, performanceCores: 16).tier, .large)
    }

    /// The ladder has exactly two rungs. A 3B was measured and REMOVED: it
    /// inverted polarity, calling publish when asked to hide, in two of three
    /// trials — and scored below the 1.5B besides. If a middle rung ever
    /// reappears, this test should fail until somebody re-measures it.
    func testThereIsNoMiddleRung() {
        XCTAssertEqual(AssistModelTier.allCases.count, 2)
        for tier in AssistModelTier.allCases {
            XCTAssertFalse(tier.displayName.contains("3B"), "The 3B inverts polarity — see AssistModelTier")
        }
    }

    /// Whatever tier is chosen, it has to leave the machine usable: never
    /// more than a third of memory resident.
    func testTheChosenModelLeavesTheMachineUsable() {
        for gigabytes in [8, 16, 24, 32, 48, 64, 128] as [Int64] {
            let hardware: AssistHardwareBudget = budget(gigabytes: gigabytes, cores: 12, performanceCores: 8)
            let third: Int64 = hardware.physicalMemoryBytes / 3
            XCTAssertLessThanOrEqual(
                hardware.tier.residentBytes, third,
                "\(gigabytes) GB chose \(hardware.tier.displayName), which would take over a third of the machine"
            )
        }
    }

    /// A Mac too small for any model still gets one. An assistant that runs
    /// slowly is more use to a teacher than one that refuses to start.
    func testATinyMachineStillGetsTheSmallModel() {
        XCTAssertEqual(AssistModelTier.fitting(budgetBytes: 1), .small)
        XCTAssertEqual(budget(gigabytes: 4, cores: 4, performanceCores: 2).tier, .small)
    }

    /// Never every core. The teacher is using this Mac while the assistant
    /// thinks, and a site build may be running in Colima at the same time.
    func testThreadCountLeavesTheMachineUsable() {
        XCTAssertEqual(budget(gigabytes: 8, cores: 8, performanceCores: 4).threadCount, 2)
        XCTAssertEqual(budget(gigabytes: 48, cores: 12, performanceCores: 8).threadCount, 4)

        let huge: AssistHardwareBudget = budget(gigabytes: 128, cores: 32, performanceCores: 24)
        XCTAssertEqual(huge.threadCount, 6, "Capped, because generation is bandwidth-bound long before it is thread-bound")
        XCTAssertLessThan(huge.threadCount, huge.performanceCoreCount)
    }

    /// Two cores is the floor, even on the smallest machine.
    func testThreadCountNeverDropsBelowTwo() {
        XCTAssertEqual(budget(gigabytes: 8, cores: 2, performanceCores: 1).threadCount, 2)
    }

    /// Ordering is the property the ladder rests on: more memory must never
    /// choose a smaller model.
    func testMoreMemoryNeverChoosesASmallerModel() {
        var previous: Int64 = 0
        for gigabytes in [4, 8, 12, 16, 24, 32, 48, 64] as [Int64] {
            let chosen: Int64 = budget(gigabytes: gigabytes, cores: 12, performanceCores: 8).tier.residentBytes
            XCTAssertGreaterThanOrEqual(chosen, previous, "\(gigabytes) GB went backwards")
            previous = chosen
        }
    }
}
