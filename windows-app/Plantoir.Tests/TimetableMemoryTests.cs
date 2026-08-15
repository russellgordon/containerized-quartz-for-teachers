using Plantoir.Core.Assist;

namespace Plantoir.Tests;

/// <summary>
/// The dates a section meets, kept so a teacher is asked for them once.
/// </summary>
public sealed class TimetableMemoryTests : IDisposable
{
    private readonly string _folder = Path.Combine(Path.GetTempPath(),
        "plantoir-timetable-" + Guid.NewGuid().ToString("N"));

    public TimetableMemoryTests() => Directory.CreateDirectory(Path.Combine(_folder, "courses"));

    public void Dispose()
    {
        try { Directory.Delete(_folder, recursive: true); } catch { }
    }

    private static readonly DateOnly Today = new(2026, 8, 13);

    [Fact]
    public void NothingIsRememberedUntilSomethingIsWritten()
    {
        Assert.Null(TimetableMemory.Read(_folder, "ICS3U", 1));
    }

    [Fact]
    public void WhatIsWrittenComesBack()
    {
        var dates = new[] { new DateOnly(2026, 9, 10), new DateOnly(2026, 9, 8) };

        Assert.True(TimetableMemory.Write(_folder, "ICS3U", 1, dates, "timetable.xlsx, block H", Today));
        var remembered = TimetableMemory.Read(_folder, "ICS3U", 1);

        Assert.NotNull(remembered);
        // Sorted on the way in, so nothing downstream has to wonder.
        Assert.Equal(new[] { new DateOnly(2026, 9, 8), new DateOnly(2026, 9, 10) }, remembered.Dates);
        Assert.Equal("timetable.xlsx, block H", remembered.Source);
        Assert.Equal(Today, remembered.Recorded);
    }

    [Fact]
    public void SectionsAreRememberedApart()
    {
        TimetableMemory.Write(_folder, "ICS3U", 1, new[] { new DateOnly(2026, 9, 8) }, "block H", Today);
        TimetableMemory.Write(_folder, "ICS3U", 2, new[] { new DateOnly(2026, 9, 9) }, "block F", Today);

        Assert.Equal(new DateOnly(2026, 9, 8), TimetableMemory.Read(_folder, "ICS3U", 1)!.Dates.Single());
        Assert.Equal(new DateOnly(2026, 9, 9), TimetableMemory.Read(_folder, "ICS3U", 2)!.Dates.Single());
        // Two sections of one course meet on different days; that is the whole
        // reason per-section publishing exists, and dates are no different.
        Assert.Equal("block F", TimetableMemory.Read(_folder, "ICS3U", 2)!.Source);
    }

    [Fact]
    public void CoursesAreRememberedApart()
    {
        TimetableMemory.Write(_folder, "ICS3U", 1, new[] { new DateOnly(2026, 9, 8) }, "block H", Today);

        Assert.NotNull(TimetableMemory.Read(_folder, "ICS3U", 1));
        Assert.Null(TimetableMemory.Read(_folder, "MPM2D", 1));
    }

    [Fact]
    public void ItLivesInsideTheCourseSoItTravelsWithIt()
    {
        // Backup, archive and restore are already careful about .internal —
        // a memory kept beside the app would come adrift the first time a
        // teacher moved their work, and be wrong rather than missing.
        TimetableMemory.Write(_folder, "ICS3U", 1, new[] { new DateOnly(2026, 9, 8) }, "block H", Today);

        string expected = Path.Combine(_folder, "courses", "ICS3U", ".internal", "timetable", "section1.json");
        Assert.True(File.Exists(expected));
    }

    [Fact]
    public void RewritingReplacesRatherThanAccumulates()
    {
        TimetableMemory.Write(_folder, "ICS3U", 1,
            new[] { new DateOnly(2026, 9, 8), new DateOnly(2026, 9, 10) }, "last year", Today);
        TimetableMemory.Write(_folder, "ICS3U", 1,
            new[] { new DateOnly(2027, 2, 2) }, "this year", Today);

        var remembered = TimetableMemory.Read(_folder, "ICS3U", 1)!;
        Assert.Equal(new DateOnly(2027, 2, 2), remembered.Dates.Single());
        Assert.Equal("this year", remembered.Source);
    }

    [Fact]
    public void DuplicateDatesAreCollapsed()
    {
        var twice = new[] { new DateOnly(2026, 9, 8), new DateOnly(2026, 9, 8) };
        TimetableMemory.Write(_folder, "ICS3U", 1, twice, "typed by hand", Today);

        Assert.Single(TimetableMemory.Read(_folder, "ICS3U", 1)!.Dates);
    }

    [Fact]
    public void AnEmptyTimetableIsNotWorthRemembering()
    {
        Assert.False(TimetableMemory.Write(_folder, "ICS3U", 1, Array.Empty<DateOnly>(), "nothing", Today));
        Assert.Null(TimetableMemory.Read(_folder, "ICS3U", 1));
    }

    [Fact]
    public void OnlyTheDatesStillToComeAreOffered()
    {
        var dates = new[]
        {
            new DateOnly(2026, 9, 8), new DateOnly(2026, 9, 10),
            new DateOnly(2026, 9, 12), new DateOnly(2026, 9, 14),
        };
        TimetableMemory.Write(_folder, "ICS3U", 1, dates, "block H", Today);

        var remaining = TimetableMemory.Read(_folder, "ICS3U", 1)!.From(new DateOnly(2026, 9, 11));

        Assert.Equal(new[] { new DateOnly(2026, 9, 12), new DateOnly(2026, 9, 14) }, remaining);
    }

    [Fact]
    public void ItCanSayHowManyDaysAreSpare()
    {
        var dates = Enumerable.Range(0, 10).Select(i => new DateOnly(2026, 9, 8).AddDays(i * 2)).ToArray();
        TimetableMemory.Write(_folder, "ICS3U", 1, dates, "block H", Today);
        var remembered = TimetableMemory.Read(_folder, "ICS3U", 1)!;

        // The question an insert asks before it moves anything: pushing 8
        // classes along leaves room for 2 more, and no further.
        Assert.Equal(2, remembered.SpareAfter(8));
        Assert.Equal(0, remembered.SpareAfter(10));
        Assert.Equal(0, remembered.SpareAfter(99));      // never negative
    }

    [Fact]
    public void RubbishOnDiskReadsAsNoMemoryRatherThanThrowing()
    {
        string path = Path.Combine(_folder, "courses", "ICS3U", ".internal", "timetable", "section1.json");
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllText(path, "{ this is not json");

        // The assistant simply asks for the timetable again, which is a good
        // day compared with a conversation that fails to start.
        Assert.Null(TimetableMemory.Read(_folder, "ICS3U", 1));
    }
}
