import Foundation

/// One day on the calendar — a year, a month and a day, and nothing else.
///
/// A section's timetable is a list of the days a class meets, written the way
/// the file format writes them: `2026-09-08`. Keeping those as calendar days
/// rather than `Date` values is deliberate. A `Date` is an instant in time, so
/// the moment one is formatted in a different time zone an early-morning class
/// slides onto the day before — and a teacher travelling east of the school
/// would be shown a plan naming the wrong dates.
///
/// Marked `nonisolated` because it is a plain value with a hand-written
/// `Comparable` conformance: the comparison has to be callable from anywhere,
/// and nothing here ever touches the main actor.
nonisolated struct CalendarDay: Comparable, Hashable, CustomStringConvertible {

    // MARK: - Stored properties

    let year: Int
    let month: Int
    let day: Int

    // MARK: - Computed properties

    /// The day exactly as the timetable file writes it: `2026-09-08`.
    var text: String {
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    var description: String {
        return text
    }

    /// "Tuesday" — for the plans a teacher reads before saying yes. A day of
    /// the week is how somebody checks a date against their own timetable,
    /// far more readily than by reading the numbers.
    var weekdayName: String {
        var components: DateComponents = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let moment = CalendarDay.calendar.date(from: components) else {
            return ""
        }
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEEE"
        return formatter.string(from: moment)
    }

    // MARK: - Initializer

    /// A real day, or nil when those numbers do not name one — the 30th of
    /// February is refused rather than quietly rolled into March.
    init?(year: Int, month: Int, day: Int) {
        var components: DateComponents = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let moment = CalendarDay.calendar.date(from: components) else {
            return nil
        }
        let rebuilt: DateComponents = CalendarDay.calendar.dateComponents([.year, .month, .day], from: moment)
        guard rebuilt.year == year, rebuilt.month == month, rebuilt.day == day else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    /// A day written `2026-09-08`, or nil when the text is anything else.
    /// Deliberately strict: one form is what the file format promises, and a
    /// date read loosely is a class scheduled on the wrong day.
    init?(text: String) {
        let trimmed: String = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 10 else {
            return nil
        }
        let characters: [Character] = Array(trimmed)
        for position in 0..<10 {
            if position == 4 || position == 7 {
                if characters[position] != "-" {
                    return nil
                }
            } else if !characters[position].isASCII || !characters[position].isNumber {
                return nil
            }
        }
        guard let year = Int(String(characters[0..<4])),
              let month = Int(String(characters[5..<7])),
              let day = Int(String(characters[8..<10])) else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }

    // MARK: - Functions

    static func < (left: CalendarDay, right: CalendarDay) -> Bool {
        if left.year != right.year {
            return left.year < right.year
        }
        if left.month != right.month {
            return left.month < right.month
        }
        return left.day < right.day
    }

    /// A fixed calendar, so the same text always means the same day whatever
    /// the machine's own settings say.
    static let calendar: Calendar = {
        var calendar: Calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    /// Today, as a calendar day in the teacher's own time zone — the day they
    /// would name if asked.
    static func today(_ moment: Date = Date(), timeZone: TimeZone = TimeZone.current) -> CalendarDay {
        var calendar: Calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components: DateComponents = calendar.dateComponents([.year, .month, .day], from: moment)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let result = CalendarDay(year: year, month: month, day: day) else {
            return CalendarDay(year: 2000, month: 1, day: 1)!
        }
        return result
    }
}
