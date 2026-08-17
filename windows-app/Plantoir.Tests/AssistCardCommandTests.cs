using System.Text.Json.Nodes;
using Plantoir.Core.Assist;

namespace Plantoir.Tests;

public class AssistCardCommandTests
{
    [Fact]
    public void CardPhrasings_AllMatchesFromContract_Pass()
    {
        var doc = ContractLoader.LoadJson("assist-cases.json");
        var matches = doc["cardPhrasings"]!["matches"]!.AsArray();

        foreach (var m in matches)
        {
            if (m is null) continue;
            string phrasing = m["phrasing"]!.ToString();
            string expectedTool = m["tool"]!.ToString();
            var expectedArgs = m["arguments"]?.AsObject();

            var matched = AssistCardCommand.Matching(phrasing);
            Assert.NotNull(matched);
            Assert.Equal(expectedTool, matched.ToolName);

            if (expectedArgs != null)
            {
                foreach (var (k, v) in expectedArgs)
                {
                    Assert.True(matched.Arguments.ContainsKey(k), $"Argument key {k} missing for {phrasing}");
                    Assert.Equal(v!.ToString(), matched.Arguments[k]);
                }
            }
        }
    }

    [Fact]
    public void CardPhrasings_AllParsedExamplesFromContract_Pass()
    {
        var doc = ContractLoader.LoadJson("assist-cases.json");
        var parsed = doc["cardPhrasings"]!["parsed"]!.AsArray();

        foreach (var p in parsed)
        {
            if (p is null) continue;
            string example = p["example"]!.ToString();
            string expectedTool = p["tool"]!.ToString();
            string notThis = p["notThis"]!.ToString();

            var matched = AssistCardCommand.Matching(example);
            Assert.NotNull(matched);
            Assert.Equal(expectedTool, matched.ToolName);

            var nearMiss = AssistCardCommand.Matching(notThis);
            Assert.Null(nearMiss);
        }
    }

    [Fact]
    public void CardPhrasings_AllNearMissesFromContract_DoNotMatch()
    {
        var doc = ContractLoader.LoadJson("assist-cases.json");
        var nearMisses = doc["nearMisses"]!["phrasings"]!.AsArray();

        foreach (var nm in nearMisses)
        {
            if (nm is null) continue;
            string phrasing = nm.ToString();

            var matched = AssistCardCommand.Matching(phrasing);
            Assert.Null(matched);
        }
    }
}
