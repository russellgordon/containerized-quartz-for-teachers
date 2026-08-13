using System.Globalization;
using System.Text;

namespace Plantoir.Core.Assist;

/// <summary>
/// A school's timetable sheet, read into dated class meetings.
///
/// The sheet's shape is a real one: a header row of single-letter block names,
/// and under each letter a PAIR of columns — the date, then either the meeting
/// number or a label for a day that is not teaching. Blocks run at different
/// times of year, so block A can start in September while block F starts in
/// October.
///
/// Two things about it need care:
///
/// * **The dates carry no year.** They read "Oct-13" … "Jun-11", running
///   across a year boundary. The academic year is inferred from today, and the
///   year rolls forward the moment the month goes backwards.
/// * **Not every row is a class.** Numbered rows are teaching meetings.
///   Everything else — <c>MB</c> (mod break), <c>INT</c> (intersession),
///   <c>Exam</c>, <c>Closing</c> — is a day the timetable knows about but no
///   unit content belongs on. They are kept and reported rather than dropped,
///   because a teacher planning a year wants to see where the exam sits.
/// </summary>
public sealed class Timetable
{
    public required string Block { get; init; }
    public required IReadOnlyList<Meeting> Meetings { get; init; }
    public required IReadOnlyList<NonTeachingDay> NonTeachingDays { get; init; }

    /// <summary>The block letters the sheet offers, for when the one asked for isn't there.</summary>
    public required IReadOnlyList<string> AvailableBlocks { get; init; }

    /// <summary>
    /// The academic year that a date with no year belongs to, worked out from
    /// today. A school year is named for the calendar year it starts in, and
    /// starts in the late summer — so in August 2026 the year is 2026/2027,
    /// and in March 2027 it is still 2026/2027.
    /// </summary>
    public static int AcademicYearStarting(DateOnly today) =>
        today.Month >= 8 ? today.Year : today.Year - 1;

    public static Timetable Parse(string csv, string block, int startYear)
    {
        var rows = ReadCsv(csv);
        int headerAt = -1;
        for (int i = 0; i < rows.Count; i++)
        {
            // A row whose every non-empty cell is a single letter, and there
            // are at least two of them. Two rather than a larger number
            // because a small school genuinely runs two or three blocks, and
            // the "every cell is one letter" test is what makes this specific.
            var letters = rows[i].Where(c => c.Trim().Length > 0).Select(c => c.Trim()).ToList();
            if (letters.Count >= 2 && letters.All(c => c.Length == 1 && char.IsLetter(c[0])))
            {
                headerAt = i;
                break;
            }
        }
        if (headerAt < 0)
            throw new AssistRefusal(
                "That sheet doesn’t look like a timetable — no row of block letters (A, B, C …) was found.");

        var header = rows[headerAt];
        var available = header.Where(c => c.Trim().Length == 1 && char.IsLetter(c.Trim()[0]))
                              .Select(c => c.Trim().ToUpperInvariant()).ToList();

        int column = -1;
        for (int i = 0; i < header.Count; i++)
            if (string.Equals(header[i].Trim(), block.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                column = i;
                break;
            }
        if (column < 0)
            throw new AssistRefusal(
                $"That timetable has no block “{block}”. It has " + string.Join(", ", available) + ".");

        var meetings = new List<Meeting>();
        var nonTeaching = new List<NonTeachingDay>();
        int year = startYear;
        int previousMonth = 0;

        for (int i = headerAt + 1; i < rows.Count; i++)
        {
            var row = rows[i];
            if (column + 1 >= row.Count) continue;
            string when = row[column].Trim();
            string marker = row[column + 1].Trim();
            if (when.Length == 0 && marker.Length == 0) continue;

            if (!TryMonthDay(when, out int month, out int day)) continue;

            // The year rolls the moment the month goes backwards.
            if (previousMonth != 0 && month < previousMonth) year++;
            previousMonth = month;

            DateOnly date;
            try { date = new DateOnly(year, month, day); }
            catch { continue; }

            if (int.TryParse(marker, NumberStyles.None, CultureInfo.InvariantCulture, out int number))
                meetings.Add(new Meeting(number, date));
            else if (marker.Length > 0)
                nonTeaching.Add(new NonTeachingDay(date, marker));
        }

        if (meetings.Count == 0)
            throw new AssistRefusal($"Block “{block}” has no numbered class meetings in that sheet.");

        return new Timetable
        {
            Block = block.Trim().ToUpperInvariant(),
            Meetings = meetings,
            NonTeachingDays = nonTeaching,
            AvailableBlocks = available,
        };
    }

    /// <summary>"Oct-13", "Jun-7", "Sep-21" — month abbreviation, then day.</summary>
    private static bool TryMonthDay(string text, out int month, out int day)
    {
        month = day = 0;
        int dash = text.IndexOf('-');
        if (dash <= 0) return false;
        string monthPart = text[..dash].Trim();
        string dayPart = text[(dash + 1)..].Trim();

        if (!int.TryParse(dayPart, NumberStyles.None, CultureInfo.InvariantCulture, out day)) return false;
        if (day is < 1 or > 31) return false;

        for (int i = 1; i <= 12; i++)
        {
            string abbreviation = CultureInfo.InvariantCulture.DateTimeFormat.GetAbbreviatedMonthName(i);
            if (monthPart.StartsWith(abbreviation, StringComparison.OrdinalIgnoreCase))
            {
                month = i;
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// An even spread of <paramref name="count"/> classes across the
    /// meetings — the STARTING POINT, not the answer.
    ///
    /// Which lesson belongs on which day is a judgement about content: a
    /// double period, a lesson that must follow an investigation, a class that
    /// would be left holding nothing but a warm-up if it were split. The tool
    /// cannot see any of that, so it offers a sensible spread and expects to
    /// be overruled by whoever can read the agendas.
    /// </summary>
    public List<Meeting> EvenSpread(int count)
    {
        if (count <= 0) return new List<Meeting>();
        if (count >= Meetings.Count) return Meetings.Take(count).ToList();

        var chosen = new List<Meeting>(count);
        for (int i = 0; i < count; i++)
        {
            // Anchors the first class on the first meeting and the last on the
            // last, so a re-dated course spans the year it was given.
            int index = count == 1 ? 0 : (int)Math.Round(i * (Meetings.Count - 1.0) / (count - 1));
            chosen.Add(Meetings[index]);
        }
        return chosen;
    }

    public Meeting? ByNumber(int number) =>
        Meetings.FirstOrDefault(m => m.Number == number) is { Number: > 0 } found ? found : null;

    /// <summary>A minimal CSV reader: quoted fields, embedded commas and newlines.</summary>
    internal static List<List<string>> ReadCsv(string text)
    {
        var rows = new List<List<string>>();
        var row = new List<string>();
        var field = new StringBuilder();
        bool quoted = false;

        for (int i = 0; i < text.Length; i++)
        {
            char c = text[i];
            if (quoted)
            {
                if (c == '"')
                {
                    if (i + 1 < text.Length && text[i + 1] == '"') { field.Append('"'); i++; }
                    else quoted = false;
                }
                else field.Append(c);
                continue;
            }
            switch (c)
            {
                case '"': quoted = true; break;
                case ',': row.Add(field.ToString()); field.Clear(); break;
                case '\r': break;
                case '\n':
                    row.Add(field.ToString()); field.Clear();
                    rows.Add(row); row = new List<string>();
                    break;
                default: field.Append(c); break;
            }
        }
        row.Add(field.ToString());
        if (row.Count > 1 || row[0].Length > 0) rows.Add(row);
        return rows;
    }
}

/// <summary>One numbered class meeting on a date.</summary>
public readonly record struct Meeting(int Number, DateOnly Date);

/// <summary>A day the timetable names but no unit content belongs on.</summary>
public readonly record struct NonTeachingDay(DateOnly Date, string Label);
