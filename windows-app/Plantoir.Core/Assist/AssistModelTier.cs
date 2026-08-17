using System;
using System.Collections.Generic;

namespace Plantoir.Core.Assist;

public enum AssistModelTier
{
    Small,
    Large
}

public static class AssistModelTiers
{
    public const long SmallDownloadBytes = 1_117_320_736L;
    public const long LargeDownloadBytes = 2_497_280_256L;

    public const long SmallResidentBytes = 1_879_048_192L;
    public const long LargeResidentBytes = 5_411_658_137L;

    public static string DisplayName(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => "the small assistant",
        AssistModelTier.Large => "the larger assistant",
        _ => "the small assistant"
    };

    public static string ChoiceLabel(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => "The smaller assistant",
        AssistModelTier.Large => "The larger assistant",
        _ => "The smaller assistant"
    };

    public static long DownloadBytes(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => SmallDownloadBytes,
        AssistModelTier.Large => LargeDownloadBytes,
        _ => SmallDownloadBytes
    };

    public static long ResidentBytes(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => SmallResidentBytes,
        AssistModelTier.Large => LargeResidentBytes,
        _ => SmallResidentBytes
    };

    public static string FileName(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => "qwen2.5-1.5b-instruct-q4_k_m.gguf",
        AssistModelTier.Large => "qwen3-4b-q4_k_m.gguf",
        _ => "qwen2.5-1.5b-instruct-q4_k_m.gguf"
    };

    public static string DownloadUrl(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
        AssistModelTier.Large => "https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf",
        _ => "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
    };

    public static string DownloadDescription(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => "1.12 GB",
        AssistModelTier.Large => "2.50 GB",
        _ => "1.12 GB"
    };

    public static string MemoryDescription(this AssistModelTier tier) => tier switch
    {
        AssistModelTier.Small => "1.75 GB",
        AssistModelTier.Large => "5.04 GB",
        _ => "1.75 GB"
    };

    public static string SizeGuidance(this AssistModelTier tier) =>
        $"{tier.DownloadDescription()} to download, and about {tier.MemoryDescription()} of memory while you are using it.";

    public static AssistModelTier ForPhysicalMemory(long bytes)
    {
        if (bytes >= 16L * 1024 * 1024 * 1024)
            return AssistModelTier.Large;
        return AssistModelTier.Small;
    }
}

public sealed class AssistHardwareBudget
{
    public long PhysicalMemoryBytes { get; }

    public AssistHardwareBudget(long? physicalMemoryBytes = null)
    {
        PhysicalMemoryBytes = physicalMemoryBytes ?? GetSystemPhysicalMemory();
    }

    public AssistModelTier Tier => AssistModelTiers.ForPhysicalMemory(PhysicalMemoryBytes);

    public string MemoryDescription
    {
        get
        {
            double gb = (double)PhysicalMemoryBytes / (1024 * 1024 * 1024);
            int roundedGb = (int)Math.Round(gb);
            return $"{roundedGb} GB";
        }
    }

    public bool IsComfortable(AssistModelTier tier)
    {
        return tier.ResidentBytes() <= PhysicalMemoryBytes / 3;
    }

    private static long GetSystemPhysicalMemory()
    {
        try
        {
            var info = GC.GetGCMemoryInfo();
            if (info.TotalAvailableMemoryBytes > 0)
                return info.TotalAvailableMemoryBytes;
        }
        catch { }
        return 16L * 1024 * 1024 * 1024; // Safe 16 GB default
    }
}

public enum AssistModelChoiceOption
{
    Automatic,
    Smaller,
    Larger
}

public static class AssistModelChoice
{
    public const string Automatic = "automatic";
    public const string Smaller = "smaller";
    public const string Larger = "larger";

    public static readonly IReadOnlyList<string> AllChoices = [Automatic, Smaller, Larger];

    public static string Label(string choice) => choice switch
    {
        Smaller => AssistModelTier.Small.ChoiceLabel(),
        Larger => AssistModelTier.Large.ChoiceLabel(),
        _ => "Choose for me"
    };

    public static AssistModelTier? NamedTier(string choice) => choice switch
    {
        Smaller => AssistModelTier.Small,
        Larger => AssistModelTier.Large,
        _ => null
    };

    public static AssistModelTier Resolved(string choice, AssistHardwareBudget budget)
    {
        var named = NamedTier(choice);
        return named ?? budget.Tier;
    }

    public static string Detail(string choice, AssistHardwareBudget budget)
    {
        var named = NamedTier(choice);
        if (named is null)
        {
            var chosen = budget.Tier;
            return $"This PC has {budget.MemoryDescription} of memory, so Plantoir uses {chosen.DisplayName()}.";
        }
        return named.Value.SizeGuidance();
    }

    public static string? Caution(string choice, AssistHardwareBudget budget)
    {
        var named = NamedTier(choice);
        if (named is null) return null;

        if (budget.IsComfortable(named.Value)) return null;

        return $"This PC has {budget.MemoryDescription} of memory, and " +
               $"{named.Value.DisplayName()} needs about {named.Value.MemoryDescription()} while it is " +
               "working — so other things you have open may slow down. You can still " +
               "choose it, and you can come back and change it.";
    }
}
