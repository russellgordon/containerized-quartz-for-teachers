using System.Text.Json.Nodes;
using Plantoir.Core.Assist;

namespace Plantoir.Tests;

public class AssistPromptHistoryTests
{
    [Fact]
    public void PromptHistory_AllContractCases_Pass()
    {
        var doc = ContractLoader.LoadJson("assist-cases.json");
        var cases = doc["promptHistory"]!["cases"]!.AsArray();

        foreach (var testCase in cases)
        {
            if (testCase is null) continue;
            string name = testCase["name"]!.ToString();
            var remember = testCase["remember"]?.AsArray();

            var history = new AssistPromptHistory();
            if (remember != null)
            {
                foreach (var r in remember)
                {
                    history.Remember(r!.ToString());
                }
            }

            if (testCase["expectEntries"] is JsonArray expectedEntries)
            {
                var actual = history.Entries;
                Assert.Equal(expectedEntries.Count, actual.Count);
                for (int i = 0; i < expectedEntries.Count; i++)
                {
                    Assert.Equal(expectedEntries[i]!.ToString(), actual[i]);
                }
            }

            if (testCase["steps"] is JsonArray steps)
            {
                foreach (var step in steps)
                {
                    string action = step!["do"]!.ToString();
                    string? typed = step["typed"]?.ToString();
                    string? expected = step["expect"]?.ToString();

                    if (action == "up")
                    {
                        string? actual = history.Earlier(typed ?? "");
                        Assert.Equal(expected, actual);
                    }
                    else if (action == "down")
                    {
                        string? actual = history.Later();
                        Assert.Equal(expected, actual);
                    }
                    else if (action == "type")
                    {
                        history.StopBrowsing();
                    }
                }
            }
        }
    }
}
