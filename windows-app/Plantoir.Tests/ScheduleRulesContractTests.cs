using System.Text.Json.Nodes;
using Plantoir.Core.Assist;

namespace Plantoir.Tests;

public class ScheduleRulesContractTests
{
    [Fact]
    public void AcceptedDateForms_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("schedule-rules.json");
        var section = doc["acceptedDateForms"]!.AsObject();
        string expectDate = section["expectDate"]!.ToString();
        var inputs = section["inputs"]!.AsArray();

        foreach (var item in inputs)
        {
            if (item is null) continue;
            string input = item.ToString();

            var outcome = SectionScheduleSource.Read(new[] { input }, "test", "test");
            Assert.IsType<ScheduleOutcome.Dates>(outcome);
            var datesOutcome = (ScheduleOutcome.Dates)outcome;
            Assert.Single(datesOutcome.Reading.Dates);
            Assert.Equal(expectDate, datesOutcome.Reading.Dates[0].ToString("yyyy-MM-dd"));
        }
    }

    [Fact]
    public void RelativeDays_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("schedule-rules.json");
        var section = doc["relativeDays"]!.AsObject();
        var today = DateOnly.Parse(section["today"]!.ToString());
        var cases = section["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            string input = c["input"]!.ToString();
            string? expectDate = c["expectDate"]?.ToString();

            var actual = SectionScheduleSource.ReadRelativeDay(input, today);
            if (expectDate is null)
            {
                Assert.Null(actual);
            }
            else
            {
                Assert.NotNull(actual);
                Assert.Equal(expectDate, actual.Value.ToString("yyyy-MM-dd"));
            }
        }
    }

    [Fact]
    public void SlashOrdering_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("schedule-rules.json");
        var section = doc["slashOrdering"]!.AsObject();
        var cases = section["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            var input = c["input"]!.AsArray().Select(x => x!.ToString()).ToList();
            if (c["expectDates"] is JsonArray expectDates)
            {
                var expected = expectDates.Select(x => x!.ToString()).ToList();
                var outcome = SectionScheduleSource.Read(input, "test", "test");
                Assert.IsType<ScheduleOutcome.Dates>(outcome);
                var datesOutcome = (ScheduleOutcome.Dates)outcome;
                Assert.Equal(expected, datesOutcome.Reading.DatesText);
            }
            else if (c["expectQuestionAbout"] is JsonNode questionAbout)
            {
                string expectAbout = questionAbout.ToString();
                var outcome = SectionScheduleSource.Read(input, "test", "test");
                Assert.IsType<ScheduleOutcome.Question>(outcome);
                var questionOutcome = (ScheduleOutcome.Question)outcome;
                Assert.Equal(expectAbout, questionOutcome.OrderingQuestion.Written);
            }
        }
    }

    [Fact]
    public void GoogleSheetLinks_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("schedule-rules.json");
        var cases = doc["googleSheetLinks"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            string input = c["input"]!.ToString();
            if (c["expectCSVURL"] is JsonNode expectCSVURL)
            {
                var url = SectionScheduleSource.CsvUrlForGoogleSheetLink(input);
                Assert.Equal(expectCSVURL.ToString(), url.ToString());
            }
            else if (c["expectProblem"] is JsonNode expectProblem)
            {
                string problemName = expectProblem.ToString();
                var ex = Assert.Throws<AssistRefusal>(() => SectionScheduleSource.CsvUrlForGoogleSheetLink(input));
                if (problemName == "aPublishedSheetLink")
                {
                    Assert.Contains("published to the web", ex.Message);
                }
                else if (problemName == "notAGoogleSheetLink")
                {
                    Assert.Contains("is not a Google Sheet link", ex.Message);
                }
            }
        }
    }

    [Fact]
    public void TabIdentifier_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("schedule-rules.json");
        var cases = doc["tabIdentifier"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            string input = c["input"]!.ToString();
            string? expectTab = c["expectTab"]?.ToString();

            string? actualTab = SectionScheduleSource.TabIdentifier(input);
            Assert.Equal(expectTab, actualTab);
        }
    }
}
