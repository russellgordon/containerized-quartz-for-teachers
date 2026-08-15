import Foundation

/// Which local model this Mac should run, and how much of the machine the
/// assistant is allowed to take while running it.
///
/// The Windows build runs one model for every machine because it has to: its
/// container gets 2 CPUs and 4 GB whatever the hardware underneath. A Mac
/// running the model natively has the whole machine to reason about, so an
/// 8 GB laptop and a 48 GB desktop should not be given the same answer.
///
/// The budget is deliberately a FRACTION of the machine rather than whatever
/// happens to be free. A teacher runs Plantoir with Obsidian open, a site
/// building in Colima, and a browser full of tabs; an assistant that sizes
/// itself to the free memory of a quiet moment will be the thing that pushes
/// that machine into swap ten minutes later.
nonisolated enum AssistModelTier: String, CaseIterable, Sendable {

    // MARK: - Cases

    /// The conservative rung, for Macs under 16 GB.
    case small

    /// The full rung, for 16 GB and up.
    case large

    // There is deliberately NO 3B rung, and this is the most important
    // comment in the file.
    //
    // Qwen2.5 3B was measured as the obvious middle step and it INVERTS
    // POLARITY: asked to hide a page it called publish_pages, in two of three
    // trials, and answered three separate hide requests with undo_last_change.
    // Publishing something a teacher asked to hide is the single dangerous
    // failure this whole design is built to prevent — it is why publish and
    // unpublish are separate verbs rather than one tool with a boolean.
    //
    // It also scored BELOW the 1.5B on the like-for-like probe set (70% against
    // 81%), so it is not even a trade of safety for accuracy. Bigger is not
    // monotonically better, and a rung that looks sensible on a spec sheet
    // earned its way out of the ladder by measurement.
    //
    // The case is removed rather than marked unsafe on purpose: the same
    // reasoning as having no delete tool. A model that cannot be selected
    // cannot be selected by accident.

    // MARK: - Computed properties

    /// What the teacher is told is running.
    ///
    /// Deliberately NOT the model's name. "Qwen3 4B" tells a teacher nothing
    /// they can act on and everything about machinery they did not ask about
    /// — the same rule that keeps "Docker", "container" and "toolchain" out
    /// of the interface. What matters to them is that this Mac gets the
    /// better one, or that a smaller one is in use and is why the assistant
    /// checks its work first.
    ///
    /// The actual model is identified by `fileName` and `downloadURL`, which
    /// are never shown.
    var displayName: String {
        switch self {
        case .small: return "the small assistant"
        case .large: return "the larger assistant"
        }
    }

    /// The download, in bytes, so a first run can say how big it is before
    /// starting and can check what it got afterwards.
    ///
    /// These are exact, and checked against the file on disk after every
    /// download — a captive portal or a proxy answers 200 with something that
    /// is not a model, and the resulting failure surfaces much later and
    /// looks like anything but a bad download. Verified by `stat` against the
    /// real files, not read off a model card.
    var downloadBytes: Int64 {
        switch self {
        case .small: return 1_117_320_736
        case .large: return 2_497_280_256
        }
    }

    /// How much context to give the model.
    ///
    /// The tool surface alone is about 3,400 tokens, so this is mostly a
    /// decision about how long a conversation can get before it truncates.
    /// 8,192 leaves roughly 4,700 tokens of room; 4,096 would leave under
    /// 700, which is why it is not offered even though it measured the same
    /// on routing.
    var contextTokens: Int {
        switch self {
        case .small: return 8_192
        case .large: return 16_384
        }
    }

    /// Roughly what the model occupies once resident.
    ///
    /// NOT the file size: most of the difference is KV cache, which scales
    /// with the context. Measured on an M4 Pro rather than calculated —
    /// Qwen3-4B is 2.5 GB of weights plus about 2.4 GB of cache at 16k, and
    /// shrinking the context gives that back with the routing bit-for-bit
    /// identical (280/290 at 16k, 8k and 4k alike).
    var residentBytes: Int64 {
        switch self {
        case .small: return 1_879_048_192   // 1.75 GB, Qwen2.5 1.5B at 8k
        case .large: return 5_411_658_137   // 5.04 GB, Qwen3 4B at 16k
        }
    }

    /// The file on disk. The tier is in the name so a machine that changes
    /// tier — a RAM upgrade, or a different Mac restoring from backup —
    /// fetches the right weights rather than reusing the wrong ones.
    var fileName: String {
        switch self {
        case .small: return "qwen2.5-1.5b-instruct-q4_k_m.gguf"
        case .large: return "qwen3-4b-q4_k_m.gguf"
        }
    }

    /// Where the weights come from. Single-file GGUFs on purpose: the
    /// official 7B repository splits its Q4_K_M in two, which a first-run
    /// downloader would have to reassemble for no benefit.
    var downloadURL: URL {
        switch self {
        case .small:
            return URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf")!
        case .large:
            return URL(string: "https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf")!
        }
    }

    /// How the download is described before it starts, so "this will take a
    /// while" is a number rather than a feeling.
    var downloadDescription: String {
        let formatter: ByteCountFormatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: downloadBytes)
    }

    // MARK: - Functions

    /// The best tier that fits the budget, never returning nothing: a Mac too
    /// small for either still gets `.small`, because an assistant that runs
    /// slowly is more use than one that refuses to start.
    static func fitting(budgetBytes: Int64) -> AssistModelTier {
        var best: AssistModelTier = .small
        for tier in [AssistModelTier.small, .large] {
            if tier.residentBytes <= budgetBytes {
                best = tier
            }
        }
        return best
    }

    /// The tier for a machine with this much physical memory.
    ///
    /// **Every rung here was chosen by measurement, and two candidates were
    /// vetoed outright.** 29 probes × 10 trials each, identical tool surface,
    /// full results in `research/ai-assist/macos-native-10-trial-comparison.txt`:
    ///
    /// | Model | Routing (Windows set) | Polarity inversions |
    /// |---|---|---|
    /// | Qwen2.5 1.5B | 79% | none |
    /// | Qwen2.5 3B | 72% | **9 of 10** |
    /// | Llama-3.2 3B | 72% | **10 of 10** |
    /// | Qwen2.5 7B | 94% | none |
    /// | **Qwen3 4B** | **100%** | **none** |
    ///
    /// Qwen3 4B beat the 7B on every axis — accuracy, latency, download and
    /// memory — so the 7B has no measured advantage left and is not shipped.
    ///
    /// **Zero inversions is a veto, not a tiebreaker.** Both 3B-class models
    /// published a page when asked to HIDE it, and they failed on the SAME
    /// sentence despite being unrelated families.
    ///
    /// Not because the page becomes visible — it does not. Publishing marks a
    /// page for inclusion; DEPLOYING is the separate act that reaches
    /// students, and `undo_last_change` takes a publish back. The veto is
    /// because an inversion is the one failure that does not announce itself:
    /// every other misroute runs a tool the teacher can see was wrong, while
    /// this one reports success and leaves the section in the OPPOSITE state
    /// to the one asked for — which the next deploy then carries out
    /// faithfully, days later, with no reason for anyone to look again.
    ///
    /// **8 GB Macs stay on the 1.5B for now, and that is a deliberate hold
    /// rather than a result.** Qwen3 4B at 8k context measured 3.87 GB
    /// resident and routes at 100%, which would be a 21-point gain on exactly
    /// the machines that get the worst model today. But 3.87 GB is 48% of an
    /// 8 GB Mac that is ALSO running Colima at 4 GB — and the assistant can
    /// start a site build itself, so those two peak together rather than
    /// taking turns. That wants trying on a real 8 GB machine with the
    /// container up, which has not been done: every measurement here is from
    /// a 48 GB M4 Pro. Until then the safe-but-mediocre model stays, because
    /// its failure is a misroute the teacher can see, not a Mac that swaps.
    static func forPhysicalMemory(bytes: Int64) -> AssistModelTier {
        let sixteenGigabytes: Int64 = 16 * 1_073_741_824
        if bytes >= sixteenGigabytes {
            return .large
        }
        return .small
    }
}

/// What the assistant is allowed to use on this Mac.
nonisolated struct AssistHardwareBudget: Sendable, Equatable {

    // MARK: - Stored properties

    /// Physical memory, in bytes.
    let physicalMemoryBytes: Int64

    /// Total logical cores.
    let coreCount: Int

    /// Performance cores, where the model actually wants to run.
    let performanceCoreCount: Int

    // MARK: - Computed properties

    /// The model this Mac should run.
    var tier: AssistModelTier {
        return AssistModelTier.forPhysicalMemory(bytes: physicalMemoryBytes)
    }

    /// How many threads llama.cpp may use.
    ///
    /// Half the performance cores, and never more than six. The teacher is
    /// using this Mac while the assistant thinks — a build may be running in
    /// Colima at the same time, which now takes real cores of its own — and
    /// generation on Apple silicon is bound by memory bandwidth long before
    /// it is bound by thread count. Taking every core buys almost nothing and
    /// makes the machine feel seized.
    var threadCount: Int {
        var threads: Int = performanceCoreCount / 2
        if threads < 2 {
            threads = 2
        }
        if threads > 6 {
            threads = 6
        }
        return threads
    }

    /// Whether this Mac can run the assistant at all. Apple silicon only:
    /// the whole design rests on Metal, and an Intel Mac would land back on
    /// the Windows numbers while looking like the same feature.
    var canRunAssistant: Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Functions

    /// This Mac, as the kernel describes it.
    static func current() -> AssistHardwareBudget {
        let memory: Int64 = Int64(ProcessInfo.processInfo.physicalMemory)
        let cores: Int = ProcessInfo.processInfo.processorCount
        var performance: Int = sysctlInt(name: "hw.perflevel0.logicalcpu") ?? cores
        if performance <= 0 {
            performance = cores
        }
        return AssistHardwareBudget(
            physicalMemoryBytes: memory,
            coreCount: cores,
            performanceCoreCount: performance
        )
    }

    /// One integer from `sysctl`, or nil when the key is not present — older
    /// Macs and Intel Macs have no `perflevel0`.
    private static func sysctlInt(name: String) -> Int? {
        var value: Int64 = 0
        var size: Int = MemoryLayout<Int64>.size
        let result: Int32 = sysctlbyname(name, &value, &size, nil, 0)
        if result != 0 {
            return nil
        }
        return Int(value)
    }
}
