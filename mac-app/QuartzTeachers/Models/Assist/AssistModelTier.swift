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

    /// Qwen2.5 1.5B — what the Windows build ships, and the floor here.
    case small

    /// Qwen2.5 7B — the model that is actually correct.
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

    /// What the teacher is told is running, if they ask.
    var displayName: String {
        switch self {
        case .small: return "Qwen2.5 1.5B"
        case .large: return "Qwen2.5 7B"
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
        case .large: return 4_683_074_240
        }
    }

    /// Roughly what the weights occupy once resident. Close enough to the
    /// file size for a budget decision, and never smaller than it.
    var residentBytes: Int64 {
        return downloadBytes
    }

    /// The file on disk. The tier is in the name so a machine that changes
    /// tier — a RAM upgrade, or a different Mac restoring from backup —
    /// fetches the right weights rather than reusing the wrong ones.
    var fileName: String {
        switch self {
        case .small: return "qwen2.5-1.5b-instruct-q4_k_m.gguf"
        case .large: return "qwen2.5-7b-instruct-q4_k_m.gguf"
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
            return URL(string: "https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf")!
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
    /// **A threshold, not a fraction of RAM, and the measurements are why.**
    /// A tidy "a fifth of memory" rule would put a 16 GB Mac on a 3.4 GB
    /// budget, which the 7B (5.15 GB resident) does not fit — so the rule
    /// would choose the smaller model on grounds of frugality. That is the
    /// wrong trade for a tool that changes what a teacher's students can see:
    ///
    /// | Model | Routing (like-for-like) | Polarity inversions |
    /// |---|---|---|
    /// | 1.5B | 81% | none |
    /// | 7B   | **94%** | none |
    ///
    /// So the question is not "what fraction of RAM is polite" but "does the
    /// correct model fit at all". 5.15 GB resident on a 16 GB Mac leaves 11 GB
    /// for the teacher, Colima and everything else, and it is only resident
    /// while the assistant window is open — closing it stops the server.
    ///
    /// | Machine | Model | First reply | Later replies |
    /// |---|---|---|---|
    /// |  8 GB | 1.5B | ~2.1 s | ~0.3 s |
    /// | 16 GB and up | 7B | ~9.5 s | ~1.2 s |
    ///
    /// Measured on an M4 Pro. The first-reply figure is the one-off read of
    /// the tool definitions, which the assistant warms in the background when
    /// its window opens, so a teacher does not normally wait for it at all.
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
