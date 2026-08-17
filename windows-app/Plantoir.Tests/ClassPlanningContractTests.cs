using System.Text.Json.Nodes;
using Plantoir.Core.Assist;
using Plantoir.Core.Models;

namespace Plantoir.Tests;

public class ClassPlanningContractTests
{
    [Fact]
    public void PageNaming_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("class-planning.json");
        var cases = doc["pageNaming"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            string title = c["title"]!.ToString();
            int? expectUnit = c["expectUnit"]?.GetValue<int>();
            int? expectDay = c["expectDay"]?.GetValue<int>();

            var parsed = UnitDay.Parse(title);
            if (expectUnit is null)
            {
                Assert.Null(parsed);
            }
            else
            {
                Assert.NotNull(parsed);
                Assert.Equal(expectUnit.Value, parsed.Value.Unit);
                Assert.Equal(expectDay!.Value, parsed.Value.Day);
            }
        }
    }

    [Fact]
    public void NumberedClassOrder_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("class-planning.json");
        var numberedOrder = doc["numberedClassOrder"]!.AsObject();
        var input = numberedOrder["input"]!.AsArray().Select(x => x!.ToString()).ToList();
        var expected = numberedOrder["expectOrder"]!.AsArray().Select(x => x!.ToString()).ToList();

        var actual = NextClassPlanner.NumberedClasses(input);
        Assert.Equal(expected, actual);
    }

    [Fact]
    public void NextClass_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("class-planning.json");
        var cases = doc["nextClass"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            var existing = c["existing"]!.AsArray().Select(x => x!.ToString()).ToList();
            int expectUnit = c["expectUnit"]!.GetValue<int>();
            int expectDay = c["expectDay"]!.GetValue<int>();

            var next = NextClassPlanner.NextUnitAndDay(existing);
            Assert.Equal(expectUnit, next.Unit);
            Assert.Equal(expectDay, next.Day);
        }
    }

    [Fact]
    public void NextClassPlanner_Date_OverflowsOntoLastDate()
    {
        var dates = new List<DateOnly>
        {
            new(2026, 9, 8),
            new(2026, 9, 10),
            new(2026, 9, 12),
        };

        Assert.Equal(new DateOnly(2026, 9, 8), NextClassPlanner.Date(0, dates, "ICS3U", 1));
        Assert.Equal(new DateOnly(2026, 9, 10), NextClassPlanner.Date(1, dates, "ICS3U", 1));
        Assert.Equal(new DateOnly(2026, 9, 12), NextClassPlanner.Date(2, dates, "ICS3U", 1));
        // Overflow past timetable count
        Assert.Equal(new DateOnly(2026, 9, 12), NextClassPlanner.Date(3, dates, "ICS3U", 1));
        Assert.Equal(new DateOnly(2026, 9, 12), NextClassPlanner.Date(10, dates, "ICS3U", 1));
    }

    [Fact]
    public void NextClassPlanner_Date_EmptyTimetable_RefusesWithInquiry()
    {
        var dates = new List<DateOnly>();
        var ex = Assert.Throws<AssistRefusal>(() => NextClassPlanner.Date(0, dates, "ICS3U", 1));
        Assert.Contains(AssistWording.MayIAskForYourDates, ex.Message);
        Assert.Contains("ICS3U Section 1", ex.Message);
    }
}
