import XCTest
@testable import QuartzTeachers

/// The settings panel: which assistant a teacher gets to choose, what they are
/// told each one costs, and what they are allowed to remove.
///
/// The rules worth pinning here are the ones a view test would never reach.
/// "Choose for me" must keep MEANING choose for me rather than being resolved
/// once and written down; a hand-picked choice must not be silently overruled
/// by the hardware; and a model must not be deleted out from under a running
/// conversation. All three are invisible in a screenshot and all three would
/// be discovered by a teacher rather than by us.
/// A box `withObservationTracking`'s `@Sendable` change handler can write to.
private final class NoticeBox: @unchecked Sendable {
    var happened: Bool = false
}

final class AssistantSettingsTests: XCTestCase {

    // MARK: - Stored properties

    /// A models folder of this test's own, so nothing here can delete the
    /// weights off the machine it is running on.
    private var modelsFolder: URL = URL(fileURLWithPath: "/")

    // MARK: - Set up

    override func setUp() {
        super.setUp()
        modelsFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("plantoir-models-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsFolder, withIntermediateDirectories: true)
        AssistModelStore.directoryOverride = modelsFolder
        // The stores are shared process-wide, so one cached against the LAST
        // test's temporary folder would answer questions about this one's.
        MainActor.assumeIsolated { AssistModelStores.reset() }
    }

    override func tearDown() {
        MainActor.assumeIsolated { AssistModelStores.reset() }
        AssistModelStore.directoryOverride = nil
        try? FileManager.default.removeItem(at: modelsFolder)
        super.tearDown()
    }

    // MARK: - Helpers

    private func budget(gigabytes: Int64) -> AssistHardwareBudget {
        return AssistHardwareBudget(
            physicalMemoryBytes: gigabytes * 1_073_741_824,
            coreCount: 8,
            performanceCoreCount: 4
        )
    }

    @MainActor
    private func library(gigabytes: Int64) -> AssistModelLibrary {
        return AssistModelLibrary(
            budget: budget(gigabytes: gigabytes),
            settings: AppSettings(defaults: TestDefaults.make())
        )
    }

    /// Puts a file of exactly the right size where the store expects one, so
    /// `isReady` is satisfied without downloading gigabytes.
    private func placeModel(for tier: AssistModelTier) throws {
        let url: URL = modelsFolder.appendingPathComponent(tier.fileName)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle: FileHandle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: UInt64(tier.downloadBytes))
        try handle.close()
    }

    // MARK: - What the choice means

    /// A teacher who never opens the panel must get exactly what they got
    /// before it existed.
    @MainActor
    func testTheFactorySettingIsToHavePlantoirChoose() {
        XCTAssertEqual(library(gigabytes: 48).choice, .automatic)
    }

    /// "Choose for me" is stored as an intent, not as an answer. If it stored
    /// the answer, a later change to the ladder would reach every Mac EXCEPT
    /// the ones whose teacher had opened Settings once.
    @MainActor
    func testChoosingForMeStillFollowsTheMachine() {
        XCTAssertEqual(AssistModelChoice.automatic.resolved(for: budget(gigabytes: 8)), .small)
        XCTAssertEqual(AssistModelChoice.automatic.resolved(for: budget(gigabytes: 48)), .large)
        XCTAssertNil(AssistModelChoice.automatic.namedTier,
                     "Automatic must not resolve to a fixed rung when it is stored")
    }

    /// A hand-picked choice wins over the hardware, in both directions. The
    /// 48 GB half is the one that matters: a teacher with a browser, a build
    /// and Obsidian open knows something `sysctl` does not.
    @MainActor
    func testAHandPickedChoiceOverridesTheMachine() {
        XCTAssertEqual(AssistModelChoice.smaller.resolved(for: budget(gigabytes: 48)), .small)
        XCTAssertEqual(AssistModelChoice.larger.resolved(for: budget(gigabytes: 8)), .large)
    }

    /// The choice is remembered across launches, which is the entire point of
    /// putting it in Settings rather than in the assistant window.
    @MainActor
    func testTheChoiceIsRememberedAcrossLaunches() {
        let defaults: UserDefaults = TestDefaults.make()
        let first: AppSettings = AppSettings(defaults: defaults)
        first.assistantModelChoice = .smaller

        let second: AppSettings = AppSettings(defaults: defaults)
        XCTAssertEqual(second.assistantModelChoice, .smaller)
    }

    /// An unreadable or retired setting falls back rather than refusing.
    @MainActor
    func testAnUnreadableSettingFallsBackToChoosingForMe() {
        let defaults: UserDefaults = TestDefaults.make()
        defaults.set("enormous", forKey: AppSettings.assistantModelChoiceKey)
        XCTAssertEqual(AppSettings(defaults: defaults).assistantModelChoice, .automatic)
    }

    // MARK: - What the teacher is told it costs

    /// Both numbers, on both rungs. Disk and memory are different decisions —
    /// disk is what runs out on a 256 GB Air, memory is what makes the machine
    /// feel slow — and neither is guessable from the other.
    func testEachOptionSaysWhatItCostsInSpaceAndInMemory() {
        for tier in AssistModelTier.allCases {
            let guidance: String = tier.sizeGuidance
            XCTAssertTrue(guidance.contains(tier.downloadDescription),
                          "\(tier) does not say how much there is to download")
            XCTAssertTrue(guidance.contains(tier.memoryDescription),
                          "\(tier) does not say how much memory it takes")
            XCTAssertTrue(guidance.lowercased().contains("download"))
            XCTAssertTrue(guidance.lowercased().contains("memory"))
        }
    }

    /// The larger one has to be described as costing more on BOTH axes, or
    /// the choice is not a choice.
    func testTheLargerOneIsTheBiggerOneOnBothCounts() {
        XCTAssertGreaterThan(AssistModelTier.large.downloadBytes, AssistModelTier.small.downloadBytes)
        XCTAssertGreaterThan(AssistModelTier.large.residentBytes, AssistModelTier.small.residentBytes)
    }

    /// Rule one of the whole product, applied to every sentence this panel can
    /// put on screen. The panel is the place a model name would most naturally
    /// leak in, because it is the one screen that is genuinely ABOUT the model.
    @MainActor
    func testNothingInThePanelNamesAModel() {
        let jargon: [String] = [
            "qwen", "llama", "gguf", "instruct", "1.5b", "4b", "7b", "3b",
            "quant", "token", "context window", "parameter", "docker",
            "container", "toolchain", "gpu", "metal", "inference"
        ]
        var shown: [String] = []
        for gigabytes in [8, 48] as [Int64] {
            let hardware: AssistHardwareBudget = budget(gigabytes: gigabytes)
            for choice in AssistModelChoice.allCases {
                shown.append(choice.label)
                shown.append(choice.detail(for: hardware))
                if let caution = choice.caution(for: hardware) {
                    shown.append(caution)
                }
            }
            let panel: AssistModelLibrary = library(gigabytes: gigabytes)
            shown.append(panel.whatHappensNext)
        }
        for tier in AssistModelTier.allCases {
            shown.append(tier.choiceLabel)
            shown.append(tier.sizeGuidance)
            shown.append(tier.memoryDescription)
        }

        for sentence in shown {
            let lowered: String = sentence.lowercased()
            for word in jargon {
                XCTAssertFalse(lowered.contains(word),
                               "\"\(sentence)\" says '\(word)' to a teacher")
            }
        }
    }

    // MARK: - Asking before it changes anything

    /// On by default, which is the important half.
    @MainActor
    func testTheAssistantAsksBeforeChangingAnythingUnlessToldOtherwise() {
        XCTAssertTrue(library(gigabytes: 48).asksBeforeChanging)
        XCTAssertTrue(AppSettings(defaults: TestDefaults.make()).assistantAsksBeforeChanging)
    }

    /// The switch and the assistant read ONE stored answer. Two switches on
    /// one behaviour is how they come to disagree.
    @MainActor
    func testTheSwitchAndThePlanGateShareOneAnswer() {
        let defaults: UserDefaults = TestDefaults.make()
        let settings: AppSettings = AppSettings(defaults: defaults)
        let panel: AssistModelLibrary = AssistModelLibrary(
            budget: budget(gigabytes: 48), settings: settings
        )

        XCTAssertTrue(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn)

        panel.asksBeforeChanging = false
        XCTAssertFalse(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn,
                       "The assistant is still asking after the switch was turned off")

        panel.asksBeforeChanging = true
        XCTAssertTrue(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn)
    }

    /// A conversation already open follows the switch, without being reopened.
    @MainActor
    func testAnOpenConversationFollowsTheSwitch() {
        let defaults: UserDefaults = TestDefaults.make()
        let settings: AppSettings = AppSettings(defaults: defaults)
        let panel: AssistModelLibrary = AssistModelLibrary(
            budget: budget(gigabytes: 48), settings: settings
        )
        let gate: AssistPlanMode = AssistPlanMode(tier: .large, settings: settings)
        XCTAssertTrue(gate.isOn)

        panel.asksBeforeChanging = false
        gate.followTheSetting()

        XCTAssertFalse(gate.isOn, "The settings window and the assistant are open at the same time")
    }

    /// The answer given before the switch existed is still honoured.
    @MainActor
    func testAnAnswerGivenBeforeTheSwitchExistedIsCarriedOver() {
        let defaults: UserDefaults = TestDefaults.make()
        defaults.set(true, forKey: AppSettings.retiredPlanModeOffKey)

        XCTAssertFalse(AppSettings(defaults: defaults).assistantAsksBeforeChanging,
                       "A teacher who had already turned plans off was asked again")
        XCTAssertFalse(AssistPlanMode(tier: .large, settings: AppSettings(defaults: defaults)).isOn)
    }

    /// Turning it off on the smaller assistant cautions rather than refuses —
    /// which one is running changes the odds, not whose decision it is.
    @MainActor
    func testTurningItOffOnTheSmallerAssistantCautionsWithTheNumber() throws {
        let panel: AssistModelLibrary = library(gigabytes: 48)
        panel.choice = .smaller

        XCTAssertNil(panel.confirmationCaution, "Nothing to caution about while it still asks")

        panel.asksBeforeChanging = false
        let caution: String = try XCTUnwrap(panel.confirmationCaution)
        XCTAssertTrue(caution.contains("one request in five"), caution)
        XCTAssertFalse(panel.asksBeforeChanging, "The caution must not overrule the teacher")

        // The larger one is not cautioned about: it measured perfect.
        panel.choice = .larger
        XCTAssertNil(panel.confirmationCaution)
    }

    /// Changing it leaves a line on the trail, because it changes what every
    /// later request DOES.
    @MainActor
    func testChangingTheSwitchLeavesALineOnTheTrail() throws {
        let folderURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("plantoir-trail-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let previous: ProblemReportStore = ActivityTrail.store
        ActivityTrail.store = ProblemReportStore(folderURL: folderURL)
        defer {
            ActivityTrail.store = previous
            try? FileManager.default.removeItem(at: folderURL)
        }

        library(gigabytes: 48).asksBeforeChanging = false

        let trail: String = ActivityTrail.store.activityText(includingPrompts: true)
        XCTAssertTrue(trail.contains("turned OFF asking"), trail)
    }

    // MARK: - The caution

    /// The caution is a caution, not a block: it appears, it names both
    /// numbers, and the option stays selectable.
    @MainActor
    func testTheCautionNamesBothNumbersOnAMacThatIsTooSmall() throws {
        let small: AssistHardwareBudget = budget(gigabytes: 8)
        let caution: String = try XCTUnwrap(
            AssistModelChoice.larger.caution(for: small),
            "An 8 GB Mac asked for the larger assistant and was told nothing"
        )
        XCTAssertTrue(caution.contains(small.memoryDescription),
                      "The caution does not say what this Mac has")
        XCTAssertTrue(caution.contains(AssistModelTier.large.memoryDescription),
                      "The caution does not say what it needs")

        let panel: AssistModelLibrary = library(gigabytes: 8)
        panel.choice = .larger
        XCTAssertEqual(panel.chosenTier, .large, "The caution must not overrule the teacher")
    }

    /// No caution where there is no problem — including on the option a
    /// too-small Mac is already being given.
    @MainActor
    func testThereIsNoCautionWhenThereIsNothingToCautionAbout() {
        XCTAssertNil(AssistModelChoice.larger.caution(for: budget(gigabytes: 48)))
        XCTAssertNil(AssistModelChoice.smaller.caution(for: budget(gigabytes: 8)))
    }

    /// "Choose for me" can never produce a caution, because the ladder is held
    /// to the same third-of-memory line the caution is measured against. If
    /// this ever fails, the ladder has drifted rather than the panel.
    @MainActor
    func testChoosingForMeNeverProducesACaution() {
        for gigabytes in [4, 8, 16, 24, 32, 48, 64, 128] as [Int64] {
            XCTAssertNil(AssistModelChoice.automatic.caution(for: budget(gigabytes: gigabytes)),
                         "\(gigabytes) GB: the automatic ladder picked something it then warned about")
        }
    }

    // MARK: - Removing one to save space

    /// The rule that cannot be discovered from a screenshot: an assistant
    /// window is open, so nothing is removed — and the teacher is told which
    /// window to close rather than that the button is unavailable.
    @MainActor
    func testRemovingIsRefusedWhileAnAssistantIsOpenAndNamesTheSection() throws {
        try placeModel(for: .large)
        let panel: AssistModelLibrary = library(gigabytes: 48)
        XCTAssertTrue(panel.mayRemove(.large), "Nothing is open, so it should be removable")

        AssistActivity.begin(folderPath: "/tmp/fixture", courseCode: "ICS3U", sectionNumber: 2)
        defer { AssistActivity.end(folderPath: "/tmp/fixture", courseCode: "ICS3U", sectionNumber: 2) }

        XCTAssertFalse(panel.mayRemove(.large))
        let reason: String = try XCTUnwrap(panel.reasonItCannotBeRemoved(.large))
        XCTAssertTrue(reason.contains("ICS3U"), reason)
        XCTAssertTrue(reason.contains("Section 2"), reason)

        panel.remove(.large)
        XCTAssertTrue(panel.isDownloaded(.large), "It was removed while a conversation was open")
    }

    /// And it becomes removable again once that window has been closed.
    @MainActor
    func testRemovingIsAllowedOnceTheAssistantIsClosed() throws {
        try placeModel(for: .large)
        let panel: AssistModelLibrary = library(gigabytes: 48)

        AssistActivity.begin(folderPath: "/tmp/fixture", courseCode: "ICS3U", sectionNumber: 2)
        AssistActivity.end(folderPath: "/tmp/fixture", courseCode: "ICS3U", sectionNumber: 2)

        XCTAssertNil(panel.reasonItCannotBeRemoved(.large))
        XCTAssertTrue(panel.mayRemove(.large))
    }

    /// Removing gets the space back, and the panel says so.
    @MainActor
    func testRemovingFreesTheSpaceAndThePanelNoticed() throws {
        try placeModel(for: .small)
        try placeModel(for: .large)
        let panel: AssistModelLibrary = library(gigabytes: 48)

        let before: Int64 = try XCTUnwrap(panel.bytesOnDisk)
        XCTAssertEqual(before, AssistModelTier.small.downloadBytes + AssistModelTier.large.downloadBytes)

        panel.remove(.large)

        XCTAssertFalse(panel.isDownloaded(.large))
        XCTAssertTrue(panel.isDownloaded(.small), "Removing one must not take the other with it")
        XCTAssertEqual(panel.bytesOnDisk, AssistModelTier.small.downloadBytes)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: modelsFolder.appendingPathComponent(AssistModelTier.large.fileName).path)
        )
    }

    /// Removing the one currently in use is ALLOWED — it is the state every
    /// Mac is in before the first download, not a broken one — and the panel
    /// then says what happens next rather than leaving a teacher guessing.
    @MainActor
    func testRemovingTheOneInUseIsAllowedAndExplained() throws {
        try placeModel(for: .large)
        let panel: AssistModelLibrary = library(gigabytes: 48)
        XCTAssertEqual(panel.chosenTier, .large)
        XCTAssertTrue(panel.whatHappensNext.lowercased().contains("ready"))

        panel.remove(.large)

        XCTAssertEqual(panel.chosenTier, .large, "Removing the file must not change the choice")
        let next: String = panel.whatHappensNext
        XCTAssertTrue(next.contains(AssistModelTier.large.downloadDescription), next)
        XCTAssertTrue(next.lowercased().contains("download"), next)
    }

    /// Nothing to remove is not the same as refusing to remove. A rung that is
    /// not here offers no button and gives no reason, because there is nothing
    /// to explain.
    @MainActor
    func testARungThatIsNotHereIsNotOfferedForRemoval() {
        let panel: AssistModelLibrary = library(gigabytes: 48)
        XCTAssertFalse(panel.mayRemove(.small))
        XCTAssertNil(panel.reasonItCannotBeRemoved(.small))
        XCTAssertNil(panel.bytesOnDisk)
    }

    /// The bug that survived closing and reopening the window.
    ///
    /// Every answer this panel gives about what is DOWNLOADED is read off the
    /// file system, and SwiftUI's observation cannot see a `FileManager` call.
    /// Removing a model therefore changed the answers and invalidated nothing
    /// — and because a `Section`'s content, header and footer are tracked
    /// separately, the rows redrew while the two summary sentences went on
    /// describing a model that had just been deleted.
    ///
    /// This asserts the thing that fixes it: reading a disk-derived answer
    /// registers a dependency that a removal trips. It is written with
    /// `withObservationTracking` rather than through a view because that is
    /// the exact mechanism SwiftUI uses, and because a view test would have
    /// passed while the panel was wrong.
    @MainActor
    func testEverySentenceAboutTheDiskRedrawsWhenTheDiskChanges() throws {
        try placeModel(for: .large)
        let panel: AssistModelLibrary = library(gigabytes: 48)

        // A reference box rather than a captured `var`: `onChange` is a
        // `@Sendable` closure, so a local variable cannot be written from it.
        let noticed: NoticeBox = NoticeBox()
        withObservationTracking {
            _ = panel.whatHappensNext
            _ = panel.bytesOnDisk
            _ = panel.isDownloaded(.large)
            _ = panel.spaceDescription(for: .large)
            _ = panel.mayRemove(.large)
        } onChange: {
            noticed.happened = true
        }

        panel.remove(.large)

        XCTAssertTrue(
            noticed.happened,
            "Removing a model changed every one of those sentences and told nobody. "
            + "The panel will keep describing a model that is no longer on the Mac."
        )
    }

    // MARK: - One file, one store

    /// The double download, pinned.
    ///
    /// The settings panel and every assistant window used to make their own
    /// `AssistModelStore` for the same path. A teacher who pressed Download in
    /// Settings and then opened the assistant got a second one, which found an
    /// incomplete file, DELETED it — that is what `download()` does to a
    /// part-finished attempt, on purpose — and started again. Two transfers
    /// writing to one destination, on a school connection, for gigabytes.
    ///
    /// Asserting the identity is what makes it impossible: one store per rung
    /// means the second caller sees the first one's progress instead of a file
    /// it does not recognise.
    @MainActor
    func testThePanelAndTheAssistantShareOneStorePerAssistant() {
        let panel: AssistModelLibrary = library(gigabytes: 48)
        let anotherPanel: AssistModelLibrary = library(gigabytes: 8)

        for tier in AssistModelTier.allCases {
            XCTAssertTrue(
                panel.store(for: tier) === AssistModelStores.store(for: tier),
                "The panel made a store of its own for \(tier)"
            )
            XCTAssertTrue(
                panel.store(for: tier) === anotherPanel.store(for: tier),
                "Two panels disagree about which store is fetching \(tier)"
            )
        }
        XCTAssertFalse(
            AssistModelStores.store(for: .small) === AssistModelStores.store(for: .large),
            "The two rungs are different files and must not share one store"
        )
    }

    /// And the flip side of sharing: the panel notices a file that appeared
    /// underneath it, once it has been asked to look again.
    ///
    /// macOS hides a settings window rather than destroying it, so the view
    /// and its state outlive every visit — without this, a panel opened in the
    /// morning would describe the morning's disk for the rest of the day.
    @MainActor
    func testAskingThePanelToLookAgainNoticesAFileThatAppeared() throws {
        let panel: AssistModelLibrary = library(gigabytes: 48)
        XCTAssertFalse(panel.isDownloaded(.large))

        try placeModel(for: .large)
        panel.refresh()

        XCTAssertTrue(panel.isDownloaded(.large))
        XCTAssertEqual(panel.bytesOnDisk, AssistModelTier.large.downloadBytes)
    }

    // MARK: - What the trail records

    /// Rule five, for this feature: a teacher can see it, so it leaves a line
    /// — and the line says which assistant they landed on, not only which
    /// button they pressed.
    @MainActor
    func testChoosingAndRemovingBothLeaveALineOnTheTrail() throws {
        let folderURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("plantoir-trail-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let previous: ProblemReportStore = ActivityTrail.store
        ActivityTrail.store = ProblemReportStore(folderURL: folderURL)
        defer {
            ActivityTrail.store = previous
            try? FileManager.default.removeItem(at: folderURL)
        }

        try placeModel(for: .small)
        let panel: AssistModelLibrary = library(gigabytes: 48)
        panel.choice = .smaller
        panel.remove(.small)

        let trail: String = ActivityTrail.store.activityText(includingPrompts: true)
        XCTAssertTrue(trail.contains("chose"), trail)
        XCTAssertTrue(trail.contains(AssistModelTier.small.displayName), trail)
        XCTAssertTrue(trail.contains("removed"), trail)
        XCTAssertTrue(trail.contains(AssistModelTier.small.downloadDescription), trail)
    }

    /// Choosing the same thing twice is not a change, and must not fill the
    /// trail with lines that describe nothing happening.
    @MainActor
    func testChoosingWhatIsAlreadyChosenRecordsNothing() throws {
        let folderURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("plantoir-trail-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let previous: ProblemReportStore = ActivityTrail.store
        ActivityTrail.store = ProblemReportStore(folderURL: folderURL)
        defer {
            ActivityTrail.store = previous
            try? FileManager.default.removeItem(at: folderURL)
        }

        let panel: AssistModelLibrary = library(gigabytes: 48)
        panel.choice = .automatic

        XCTAssertFalse(ActivityTrail.store.activityText(includingPrompts: true).contains("chose"))
    }

    // MARK: - What the engine is actually started with

    /// The trap this feature introduced, pinned. The tier decides the CONTEXT
    /// SIZE, so a server host that took it from the hardware would hand the
    /// smaller assistant the larger one's window — several times the memory
    /// the teacher chose it to save, which is the opposite of what they asked
    /// for and is invisible until the machine starts swapping.
    @MainActor
    func testTheEngineIsStartedWithTheChosenAssistantNotTheMachines() {
        let host: AssistServerHost = AssistServerHost(
            modelURL: URL(fileURLWithPath: "/tmp/nothing.gguf"),
            budget: budget(gigabytes: 48),
            tier: .small
        )
        XCTAssertEqual(host.tier, .small)

        let arguments: [String] = AssistServerHost.serverArguments(
            modelPath: "/tmp/nothing.gguf", port: 1234, tier: host.tier, threadCount: 4
        )
        XCTAssertTrue(arguments.contains("\(AssistModelTier.small.contextTokens)"),
                      "The engine was not given the smaller assistant's context: \(arguments)")
        XCTAssertFalse(arguments.contains("\(AssistModelTier.large.contextTokens)"),
                       "The engine was given the larger assistant's context: \(arguments)")
    }
}
