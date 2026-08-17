using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Plantoir.Core.Assist;

namespace Plantoir.Core.Models;

public static class CourseRenamer
{
    public sealed record Outcome(
        string NewCode,
        IReadOnlyList<int> StoppedScheduledSections,
        IReadOnlyList<int> UnstoppedScheduledSections)
    {
        public bool IsQuiet => StoppedScheduledSections.Count == 0 && UnstoppedScheduledSections.Count == 0;
    }

    public sealed record Notice(string Title, string Message);

    public static Notice? NoticeAfterRenaming(Outcome outcome)
    {
        if (outcome.IsQuiet) return null;
        if (outcome.StoppedScheduledSections.Count > 0 && outcome.UnstoppedScheduledSections.Count == 0)
        {
            string sections = string.Join(", ", outcome.StoppedScheduledSections.Select(s => $"Section {s}"));
            return new Notice(
                "Scheduled publishing turned off",
                $"Scheduled publishing for {sections} was turned off because the course code changed. Turn it back on in Course Settings if you would like it to continue.");
        }
        if (outcome.UnstoppedScheduledSections.Count > 0)
        {
            string sections = string.Join(", ", outcome.UnstoppedScheduledSections.Select(s => $"Section {s}"));
            return new Notice(
                "Scheduled publishing could not be cancelled",
                $"Scheduled publishing for {sections} could not be turned off automatically. Check your task scheduler so it does not run against a missing course.");
        }
        return null;
    }

    public static Outcome Rename(
        Course course,
        string requestedCode,
        string coursesDirectory,
        IEnumerable<string> existingCodes)
    {
        string newCode = CourseCodeValidator.Normalize(requestedCode);
        if (CourseCodeValidator.Problem(requestedCode, existingCodes, course.Code) is { } problem)
        {
            throw new InvalidOperationException(problem);
        }

        if (string.IsNullOrEmpty(newCode) || newCode == course.Code)
        {
            return new Outcome(course.Code, Array.Empty<int>(), Array.Empty<int>());
        }

        string destinationDir = Path.Combine(coursesDirectory, newCode);
        if (Directory.Exists(destinationDir) || File.Exists(destinationDir))
        {
            throw new InvalidOperationException($"There is already something called {newCode} in this working folder.");
        }

        var scheduledSections = new List<int>();
        foreach (int section in course.SectionNumbers)
        {
            if (TaskScheduling.Exists(TaskScheduling.NameFor(course.Code, section)))
                scheduledSections.Add(section);
        }

        string previousCode = course.Code;
        course.Configuration.SetCourseCode(newCode);
        try
        {
            course.Configuration.Write(course.ConfigFilePath);
        }
        catch (Exception ex)
        {
            course.Configuration.SetCourseCode(previousCode);
            throw new InvalidOperationException($"The course's settings could not be saved: {ex.Message}", ex);
        }

        try
        {
            Directory.Move(course.DirectoryPath, destinationDir);
        }
        catch (Exception ex)
        {
            course.Configuration.SetCourseCode(previousCode);
            try { course.Configuration.Write(course.ConfigFilePath); } catch { }
            throw new InvalidOperationException($"The course's folder could not be renamed: {ex.Message}", ex);
        }

        var stopped = new List<int>();
        var unstopped = new List<int>();
        foreach (int section in scheduledSections)
        {
            string? cancelError = TaskScheduling.Cancel(TaskScheduling.NameFor(previousCode, section));
            if (cancelError is null)
                stopped.Add(section);
            else
                unstopped.Add(section);
        }

        return new Outcome(newCode, stopped, unstopped);
    }
}
