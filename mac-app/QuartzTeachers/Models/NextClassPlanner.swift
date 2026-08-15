import Foundation

/// The page for the next class: the one that comes after the last one a
/// section has, on the next day it meets.
///
/// This is the end of a lesson, in one sentence. A teacher has just finished
/// teaching, wants tomorrow's page to exist so they can start writing it, and
/// today opens frontmatter to do it — working out which number comes next and
/// which date that number falls on. Neither of those is a judgement; both are
/// arithmetic somebody keeps doing by hand.
///
/// **The number and the date are worked out separately, and that is the whole
/// design.** They answer different questions:
///
/// * The NUMBER continues the unit being taught. The highest unit any class
///   page names, then the highest day inside that unit, plus one: Unit 3,
///   Day 2 becomes Unit 3, Day 3. A new unit is a decision a teacher makes, not
///   one a tool should make for them — `PlaceholderClassPlanner` is how a unit
///   gets started.
/// * The DATE comes from POSITION IN THE TIMETABLE. Count the class pages the
///   section already has, add one, and take that many dates into the remembered
///   timetable: 15 class pages means the 16th recorded date. It is deliberately
///   NOT derived from the unit and day numbering — three units of five days are
///   fifteen classes whatever they are called, and a course where a unit ran
///   long, or where a page is called "Field Trip" rather than Unit 2, Day 4,
///   would date every later class wrongly if the numbers were trusted.
///
/// Nothing here writes. The plan it returns is a `PlaceholderClassPlan`, so the
/// page is created by `PlaceholderClassPlanner.apply` — which already refuses
/// to write over an existing page, checks that twice, and starts new pages
/// `publish: false`.
enum NextClassPlanner {

    // MARK: - Types

    /// Why a next class could not be planned, in words a teacher can act on.
    ///
    /// **Neither message names a tool.** They used to say "record them with
    /// `remember_timetable` first", which was a dead end the day that tool
    /// came off the local surface: the model was being sent to something it
    /// could no longer see, and would either give up or invent dates of its
    /// own. Asking for the dates is the APP's job now — `AssistToolRunner`
    /// opens the schedule sheet when it sees `noTimetable` — so these say what
    /// is missing and who is being asked, and leave the how alone. That also
    /// keeps them true on the MCP surface, where the client's tool list is
    /// different again.
    enum Problem: LocalizedError {
        case noTimetable(String, Int)
        case timetableRanOut(String, Int, Int, Int)

        var errorDescription: String? {
            switch self {
            case .noTimetable(let code, let number):
                return "I don’t know when \(code) Section \(number) meets, so I can’t date a new class. Plantoir is asking the teacher for this section’s class dates now — once they have given them, ask again."
            case .timetableRanOut(let code, let number, let classes, let dates):
                return "\(code) Section \(number) has \(classes) class page\(classes == 1 ? "" : "s") and only \(dates) class date\(dates == 1 ? "" : "s") on file, so there is no date left for another class. The teacher needs to give the rest of the section’s dates before another class can be added."
            }
        }
    }

    // MARK: - Functions

    /// What adding the next class would do. Changes nothing.
    static func plan(forSection sectionNumber: Int, in course: Course) throws -> PlaceholderClassPlan {
        guard let remembered = try SectionTimetableStore.read(forSection: sectionNumber, in: course) else {
            throw Problem.noTimetable(course.code, sectionNumber)
        }

        let existing: [ClassPageSummary] = ClassPages.list(forSection: sectionNumber, in: course)
        let next: UnitDay = nextUnitAndDay(after: existing)

        // Position, not numbering: the class after this section's 15th class
        // takes the 16th date, whatever the 15 pages happen to be called.
        let position: Int = existing.count
        if position >= remembered.dates.count {
            throw Problem.timetableRanOut(
                course.code, sectionNumber, existing.count, remembered.dates.count
            )
        }
        let date: CalendarDay = remembered.dates[position]

        let pageURL: URL = ClassPages.folderURL(forSection: sectionNumber, in: course)
            .appendingPathComponent(next.title + ".md")

        // The first of the two checks that nothing is ever written over. The
        // second is in `PlaceholderClassPlanner.apply`, because Obsidian is
        // open in the other window and a page can appear in between.
        var classes: [PlannedClass] = []
        var alreadyThere: [String] = []
        if FileManager.default.fileExists(atPath: pageURL.path) {
            alreadyThere.append(next.title)
        } else {
            classes.append(PlannedClass(
                title: next.title, fileURL: pageURL, day: next.day, date: date
            ))
        }

        return PlaceholderClassPlan(
            courseCode: course.code,
            sectionNumber: sectionNumber,
            unit: next.unit,
            classes: classes,
            alreadyThere: alreadyThere,
            problems: [],
            spareDatesLeft: max(0, remembered.dates.count - (position + 1)),
            timetableSource: remembered.source
        )
    }

    /// The unit and day a new class page would carry: the highest unit these
    /// pages name, and one past the highest day inside it.
    ///
    /// Pages named some other way — "Field Trip", "Exam Review" — carry no
    /// numbers and are passed over here, exactly as they are everywhere else
    /// that renumbers classes. A section with no numbered class at all starts
    /// at Unit 1, Day 1.
    static func nextUnitAndDay(after pages: [ClassPageSummary]) -> UnitDay {
        var highestUnit: Int = 0
        for page in pages {
            if let numbers = page.unitAndDay, numbers.unit > highestUnit {
                highestUnit = numbers.unit
            }
        }
        if highestUnit == 0 {
            return UnitDay(unit: 1, day: 1)
        }

        var highestDay: Int = 0
        for page in pages {
            guard let numbers = page.unitAndDay, numbers.unit == highestUnit else {
                continue
            }
            if numbers.day > highestDay {
                highestDay = numbers.day
            }
        }
        return UnitDay(unit: highestUnit, day: highestDay + 1)
    }
}
