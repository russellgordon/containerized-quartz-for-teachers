namespace Plantoir.Core.Models;

/// <summary>One course/club folder under &lt;workspace&gt;/courses/, plus its loaded config.</summary>
public sealed class Course
{
    /// <summary>The course code — also the folder name (e.g. ICS3U).</summary>
    public string Code { get; }

    /// <summary>&lt;workspace&gt;/courses/&lt;CODE&gt;</summary>
    public string DirectoryPath { get; }

    public CourseConfiguration Configuration { get; }

    public Course(string code, string directoryPath, CourseConfiguration configuration)
    {
        Code = code;
        DirectoryPath = directoryPath;
        Configuration = configuration;
    }

    public List<int> SectionNumbers => Configuration.SectionNumbers;

    public string ConfigFilePath => Path.Combine(DirectoryPath, "course_config.json");

    public string SectionDirectory(int number) => Path.Combine(DirectoryPath, "section" + number);
}
