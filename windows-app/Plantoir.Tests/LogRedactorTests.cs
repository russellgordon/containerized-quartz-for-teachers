using System.Text.Json.Nodes;
using Plantoir.Core.Scripting;

namespace Plantoir.Tests;

public class LogRedactorTests
{
    [Fact]
    public void LogRedactor_AllContractCases_Pass()
    {
        var doc = ContractLoader.LoadJson("shared-rules.json");
        var cases = doc["problemReportRedaction"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            string input = c["input"]!.ToString();
            string expected = c["expect"]!.ToString();

            string actual = LogRedactor.Redacting(input);
            Assert.Equal(expected, actual);
        }
    }
}
