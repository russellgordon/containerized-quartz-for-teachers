using System.Collections.Generic;
using System.IO;

namespace Plantoir.Core.Models;

public sealed record FolderCrumb(string Path)
{
    public string DisplayName =>
        System.IO.Path.GetFileName(Path.TrimEnd('\\')) is { Length: > 0 } name ? name : Path;

    public override string ToString() => DisplayName;

    public static List<string> AncestorPaths(string path)
    {
        var parts = new List<string>();
        var directory = new DirectoryInfo(path);
        for (var current = directory; current is not null; current = current.Parent)
            parts.Insert(0, current.FullName);
        return parts;
    }

    public static List<FolderCrumb> ForPath(string path) =>
        AncestorPaths(path).ConvertAll(p => new FolderCrumb(p));
}
