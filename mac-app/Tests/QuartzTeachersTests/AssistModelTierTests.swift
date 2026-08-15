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
        // Checked against the FILE name, not the display name: what a teacher
        // is shown is deliberately plain language and says nothing about
        // which model is running.
        for tier in AssistModelTier.allCases {
            XCTAssertFalse(tier.fileName.contains("-3b-"), "A 3B inverts polarity — see AssistModelTier")
            XCTAssertFalse(tier.fileName.contains("3b-instruct"), "A 3B inverts polarity — see AssistModelTier")
        }
    }

    /// Nothing a teacher reads names the model. "Qwen3 4B" tells them nothing
    /// they can act on, and it is the same rule that keeps "Docker" and
    /// "container" out of the interface.
    func testWhatTheTeacherIsShownNamesNoModel() {
        let jargon: [String] = ["qwen", "llama", "gguf", "instruct", "1.5b", "4b", "7b", "3b"]
        for tier in AssistModelTier.allCases {
            let shown: String = tier.displayName.lowercased()
            for word in jargon {
                XCTAssertFalse(shown.contains(word), "\(tier.displayName) says '\(word)' to a teacher")
            }
            XCTAssertTrue(shown.contains("assistant"), "It should read as the assistant, in plain words")
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

    // MARK: - The engine's arguments

    /// The single most consequential flag in the whole feature.
    ///
    /// Qwen3 with thinking enabled spends its token budget inside `<think>`
    /// and never reaches the tool call. Measured on identical weights: 39%
    /// routing with thinking on, 97% with it off. Losing this flag would not
    /// break anything visibly — the assistant would simply become bad at its
    /// job — so it is asserted here rather than trusted.
    func testThinkingIsTurnedOff() {
        for tier in AssistModelTier.allCases {
            let arguments: [String] = AssistServerHost.serverArguments(
                modelPath: "/tmp/model.gguf", port: 8080, tier: tier, threadCount: 4
            )
            guard let flagAt = arguments.firstIndex(of: "--reasoning-budget") else {
                return XCTFail("\(tier.displayName) starts without --reasoning-budget; thinking would be on")
            }
            XCTAssertEqual(arguments[arguments.index(after: flagAt)], "0",
                           "A budget above zero lets the model think instead of calling a tool")
        }
    }

    /// Metal is the entire reason for running natively rather than in Colima.
    /// A partial offload would leave the slow path in play.
    func testEveryLayerGoesToTheGPU() {
        let arguments: [String] = AssistServerHost.serverArguments(
            modelPath: "/tmp/model.gguf", port: 8080, tier: .large, threadCount: 4
        )
        guard let flagAt = arguments.firstIndex(of: "--n-gpu-layers") else {
            return XCTFail("Without --n-gpu-layers the model runs on the CPU")
        }
        XCTAssertEqual(arguments[arguments.index(after: flagAt)], "999")
    }

    /// The context is most of what the model holds in memory, so the tiers
    /// must not be handed the same figure.
    func testTheContextIsSizedByTier() {
        XCTAssertEqual(AssistModelTier.small.contextTokens, 8_192)
        XCTAssertEqual(AssistModelTier.large.contextTokens, 16_384)

        // The tool surface alone is ~3,400 tokens. Anything at or below 4,096
        // leaves under 700 for the conversation and truncates on a multi-turn
        // chat, however well it measures on single-turn routing.
        for tier in AssistModelTier.allCases {
            XCTAssertGreaterThan(tier.contextTokens, 4_096,
                                 "\(tier.displayName) would truncate a conversation after the tool surface")
        }
    }

    /// Tool calling is what the whole surface depends on, and it comes from
    /// the model's own template rather than a guess at its format.
    func testToolCallingUsesTheModelsOwnTemplate() {
        let arguments: [String] = AssistServerHost.serverArguments(
            modelPath: "/tmp/model.gguf", port: 8080, tier: .large, threadCount: 4
        )
        XCTAssertTrue(arguments.contains("--jinja"))
    }
}
