import Foundation

/// One page whose visibility would move.
struct AssistPublishChange {

    // MARK: - Stored properties

    let page: AssistSectionPage

    /// The frontmatter key that decides it — named in the plan so a teacher
    /// reading the plan can go and look at the same line.
    let key: String

    let wasVisible: Bool
    let willBeVisible: Bool

    /// True when this page was reached by following a link rather than named.
    let becauseLinked: Bool
}

/// One page whose date would move onto the class's day.
struct AssistPublishDateMove {

    // MARK: - Stored properties

    let page: AssistSectionPage
    let from: CalendarDay?
    let to: CalendarDay
}

/// What publishing (or unpublishing) would do, before anything is done.
///
/// The plan is the object BOTH halves work from: `plan_publish_pages` describes
/// it and stops, `publish_pages` describes it and applies it. One description
/// of the change, in one place — two would drift, and the day they drift is the
/// day a teacher agrees to one thing and gets another.
struct AssistPublishPlan {

    // MARK: - Stored properties

    let courseCode: String
    let sectionNumber: Int

    /// The verb. Not a setting the caller may flip afterwards: it is decided
    /// by WHICH TOOL RAN, and it travels with the plan so that nothing between
    /// the plan and the write can invert it.
    let publishes: Bool

    /// The pages the model named that matched nothing.
    let unknownNames: [String]

    let changes: [AssistPublishChange]

    /// Pages already the way they were asked to be.
    let alreadyRight: [AssistSectionPage]

    let dateMoves: [AssistPublishDateMove]

    // MARK: - Computed properties

    var changesNothing: Bool {
        return changes.isEmpty && dateMoves.isEmpty
    }

    var verb: String {
        return publishes ? "publish" : "unpublish"
    }

    // MARK: - Functions

    /// The plan in words, meant to be read aloud to a teacher.
    func describe(mostListed: Int = 15) -> String {
        var lines: [String] = []
        lines.append("\(courseCode) Section \(sectionNumber): \(verb)ing.")
        lines.append("")

        if changes.isEmpty {
            lines.append("No page's visibility would change.")
        } else {
            let word: String = changes.count == 1 ? "page" : "pages"
            lines.append("\(changes.count) \(word) would change:")
            var listed: Int = 0
            for change in changes {
                if listed == mostListed {
                    lines.append("  …and \(changes.count - listed) more.")
                    break
                }
                let reason: String = change.becauseLinked ? "  (linked from a page you named)" : ""
                lines.append("  \(change.page.title)  —  \(change.key): "
                             + "\(change.wasVisible ? "visible" : "hidden") → "
                             + "\(change.willBeVisible ? "visible" : "hidden")\(reason)")
                listed += 1
            }
        }

        if !alreadyRight.isEmpty {
            let word: String = alreadyRight.count == 1 ? "page is" : "pages are"
            lines.append("\(alreadyRight.count) \(word) already \(publishes ? "visible" : "hidden").")
        }

        if !dateMoves.isEmpty {
            lines.append("")
            let word: String = dateMoves.count == 1 ? "page" : "pages"
            lines.append("\(dateMoves.count) \(word) no other class uses would take this class's date:")
            var listed: Int = 0
            for move in dateMoves {
                if listed == mostListed {
                    lines.append("  …and \(dateMoves.count - listed) more.")
                    break
                }
                let from: String = move.from?.text ?? "no date"
                lines.append("  \(move.page.title)  —  \(from) → \(move.to.text)")
                listed += 1
            }
        }

        if !unknownNames.isEmpty {
            lines.append("")
            lines.append("No page in this section is called "
                         + AssistPublishPlan.listing(unknownNames) + ".")
        }

        return lines.joined(separator: "\n")
    }

    /// "a", "a and b", "a, b and c" — the way a sentence says a list.
    static func listing(_ names: [String]) -> String {
        var quoted: [String] = []
        for name in names {
            quoted.append("“\(name)”")
        }
        if quoted.count <= 1 {
            return quoted.first ?? ""
        }
        let last: String = quoted.removeLast()
        return quoted.joined(separator: ", ") + " and " + last
    }
}

/// Working out what a publish or an unpublish would do, and doing it.
///
/// Publishing and unpublishing come through here as two separate entry points
/// that each hard-code their own verb. There is no `publish: Bool` to pass in
/// from outside, because the one genuinely dangerous failure ever observed was
/// polarity inversion — asked to HIDE a page, the model called publish with
/// "include everything it links to" set. A boolean is a coin flip under
/// pressure; a verb is not.
enum AssistPublishPlanner {

    // MARK: - Functions

    /// What publishing these pages would do.
    static func planPublishing(
        titles: [String],
        includeLinked: Bool,
        onOrAfter: CalendarDay?,
        before: CalendarDay?,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary],
        forSection sectionNumber: Int,
        in course: Course
    ) -> AssistPublishPlan {
        return plan(
            publishes: true, titles: titles, includeLinked: includeLinked,
            onOrAfter: onOrAfter, before: before, graph: graph, classPages: classPages,
            dateMoves: [], forSection: sectionNumber, in: course
        )
    }

    /// What unpublishing these pages would do.
    static func planUnpublishing(
        titles: [String],
        includeLinked: Bool,
        onOrAfter: CalendarDay?,
        before: CalendarDay?,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary],
        forSection sectionNumber: Int,
        in course: Course
    ) -> AssistPublishPlan {
        return plan(
            publishes: false, titles: titles, includeLinked: includeLinked,
            onOrAfter: onOrAfter, before: before, graph: graph, classPages: classPages,
            dateMoves: [], forSection: sectionNumber, in: course
        )
    }

    /// What publishing the class taught on a given day would do.
    ///
    /// The coarse one. It finds the class by date, follows its links, and works
    /// out which pages should take the class's date — all in ordinary code,
    /// rather than leaving the model to chain three calls and choose an order.
    /// That single decision took an 8-of-8 failure to 8-of-8 correct on
    /// Windows, and it is the reason this function exists at all.
    static func planPublishingClass(
        on day: CalendarDay,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary],
        forSection sectionNumber: Int,
        in course: Course
    ) -> Result<AssistPublishPlan, AssistToolRefusal> {
        var matching: [ClassPageSummary] = []
        for summary in classPages where summary.date == day {
            matching.append(summary)
        }
        if matching.isEmpty {
            return .failure(.noClassOn(day, course.code, sectionNumber))
        }

        var titles: [String] = []
        for summary in matching {
            titles.append(summary.title)
        }

        let moves: [AssistPublishDateMove] = dateMoves(
            forClassesTitled: titles, on: day, graph: graph, classPages: classPages
        )
        return .success(plan(
            publishes: true, titles: titles, includeLinked: true,
            onOrAfter: nil, before: nil, graph: graph, classPages: classPages,
            dateMoves: moves, forSection: sectionNumber, in: course
        ))
    }

    /// The shared machinery. Private, and the verb arrives as an argument only
    /// here — the two public entry points above are the only callers, and each
    /// of them writes the verb down literally.
    private static func plan(
        publishes: Bool,
        titles: [String],
        includeLinked: Bool,
        onOrAfter: CalendarDay?,
        before: CalendarDay?,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary],
        dateMoves: [AssistPublishDateMove],
        forSection sectionNumber: Int,
        in course: Course
    ) -> AssistPublishPlan {
        var named: [AssistSectionPage] = []
        var unknownNames: [String] = []
        var chosen: Set<String> = []

        for title in titles {
            guard let page = graph.page(titled: title) else {
                unknownNames.append(title.trimmingCharacters(in: .whitespaces))
                continue
            }
            if chosen.contains(page.lowercasedTitle) {
                continue
            }
            chosen.insert(page.lowercasedTitle)
            named.append(page)
        }

        // The dates are compared here rather than by the model: "every class
        // from September 15th" is one call, and a comparison the model never
        // makes is a comparison it never gets wrong.
        if onOrAfter != nil || before != nil {
            for summary in classPages {
                guard let date = summary.date else {
                    continue
                }
                if let onOrAfter, date < onOrAfter {
                    continue
                }
                if let before, !(date < before) {
                    continue
                }
                guard let page = graph.page(titled: summary.title) else {
                    continue
                }
                if chosen.contains(page.lowercasedTitle) {
                    continue
                }
                chosen.insert(page.lowercasedTitle)
                named.append(page)
            }
        }

        var linked: [AssistSectionPage] = []
        if includeLinked {
            linked = graph.linkedPages(from: named)
        }

        var changes: [AssistPublishChange] = []
        var alreadyRight: [AssistSectionPage] = []
        appendChanges(
            for: named, becauseLinked: false, publishes: publishes,
            forSection: sectionNumber, into: &changes, alreadyRight: &alreadyRight
        )
        appendChanges(
            for: linked, becauseLinked: true, publishes: publishes,
            forSection: sectionNumber, into: &changes, alreadyRight: &alreadyRight
        )

        // A page whose date would move but whose visibility is already right
        // still has to be written, so the date moves are carried through whole
        // rather than filtered against the visibility changes.
        return AssistPublishPlan(
            courseCode: course.code,
            sectionNumber: sectionNumber,
            publishes: publishes,
            unknownNames: unknownNames,
            changes: changes,
            alreadyRight: alreadyRight,
            dateMoves: dateMoves
        )
    }

    private static func appendChanges(
        for pages: [AssistSectionPage],
        becauseLinked: Bool,
        publishes: Bool,
        forSection sectionNumber: Int,
        into changes: inout [AssistPublishChange],
        alreadyRight: inout [AssistSectionPage]
    ) {
        for page in pages {
            if page.isVisibleToStudents == publishes {
                alreadyRight.append(page)
                continue
            }
            guard let text = try? String(contentsOf: page.fileURL, encoding: .utf8) else {
                continue
            }
            changes.append(AssistPublishChange(
                page: page,
                key: AssistPageVisibility.keyInUse(
                    in: text, forSection: sectionNumber, isSectionLocal: page.isSectionLocal
                ),
                wasVisible: page.isVisibleToStudents,
                willBeVisible: publishes,
                becauseLinked: becauseLinked
            ))
        }
    }

    /// The pages a class uses that no OTHER class uses, and so should sit on
    /// that class's day.
    ///
    /// A concept page linked from three different lessons belongs to none of
    /// them and is left exactly where it is. One linked from a single lesson is
    /// that lesson's material, and a teacher expects it to appear under the
    /// same day.
    static func dateMoves(
        forClassesTitled titles: [String],
        on day: CalendarDay,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary]
    ) -> [AssistPublishDateMove] {
        var theseClasses: Set<String> = []
        for title in titles {
            theseClasses.insert(AssistSectionGraph.normalized(title))
        }

        // How many class pages link to each page, counting the ones being
        // published as one between them.
        var usedByOtherClass: Set<String> = []
        for summary in classPages {
            let classTitle: String = AssistSectionGraph.normalized(summary.title)
            if theseClasses.contains(classTitle) {
                continue
            }
            guard let page = graph.page(titled: summary.title) else {
                continue
            }
            for target in page.linkedTitles {
                usedByOtherClass.insert(target)
            }
        }

        var starting: [AssistSectionPage] = []
        for title in titles {
            if let page = graph.page(titled: title) {
                starting.append(page)
            }
        }

        var moves: [AssistPublishDateMove] = []
        for page in graph.linkedPages(from: starting) {
            if usedByOtherClass.contains(page.lowercasedTitle) {
                continue
            }
            if page.date == day {
                continue
            }
            moves.append(AssistPublishDateMove(page: page, from: page.date, to: day))
        }
        return moves
    }

    /// Carry the plan out. Returns the change record so it can be undone.
    static func apply(
        _ plan: AssistPublishPlan,
        forSection sectionNumber: Int,
        in course: Course
    ) throws -> AssistChange {
        // Every file this plan touches, gathered first, so a page that both
        // changes visibility and moves date is written once.
        var editsByPath: [String: (url: URL, isSectionLocal: Bool)] = [:]
        var publishByPath: [String: Bool] = [:]
        var dateByPath: [String: CalendarDay] = [:]

        for change in plan.changes {
            let path: String = change.page.fileURL.path
            editsByPath[path] = (change.page.fileURL, change.page.isSectionLocal)
            publishByPath[path] = change.willBeVisible
        }
        for move in plan.dateMoves {
            let path: String = move.page.fileURL.path
            editsByPath[path] = (move.page.fileURL, move.page.isSectionLocal)
            dateByPath[path] = move.to
        }

        var paths: [String] = []
        for (path, _) in editsByPath {
            paths.append(path)
        }
        paths.sort()

        let tail: String = ClassPages.siblingTimeAndOffset(
            from: ClassPages.list(forSection: sectionNumber, in: course),
            forSection: sectionNumber
        )

        var saved: [AssistSavedFile] = []
        for path in paths {
            guard let edit = editsByPath[path] else {
                continue
            }
            let before: String = try String(contentsOf: edit.url, encoding: .utf8)
            var text: String = before

            if let published = publishByPath[path] {
                text = AssistPageVisibility.setting(
                    published: published, in: text,
                    forSection: sectionNumber, isSectionLocal: edit.isSectionLocal
                ).text
            }
            if let day = dateByPath[path] {
                text = PageFrontmatter.settingCreated(
                    in: text,
                    key: PageFrontmatter.createdKey(
                        forSection: sectionNumber, isSectionLocal: edit.isSectionLocal
                    ),
                    to: day,
                    fallbackTail: tail
                ).text
            }

            if text == before {
                continue
            }
            try text.write(to: edit.url, atomically: true, encoding: .utf8)
            saved.append(AssistSavedFile(fileURL: edit.url, before: before, after: text))
        }

        let word: String = saved.count == 1 ? "page" : "pages"
        return AssistChange(
            description: "\(plan.verb)ed \(saved.count) \(word) in \(plan.courseCode) Section \(sectionNumber)",
            files: saved
        )
    }
}

/// A reason a tool did not go ahead, in words a teacher can act on.
///
/// A refusal is an ANSWER, not a crash: it comes back as ordinary text so the
/// assistant reads the reason out and can correct itself.
enum AssistToolRefusal: LocalizedError, Equatable {
    case noWorkingFolder
    case noSuchCourse(String)
    case noSuchSection(String, Int)
    case noSuchPage(String, String, Int)
    case unreadablePage(String)
    case noClassOn(CalendarDay, String, Int)
    case unreadableDate(String, String)
    case unreadableTime(String)
    case nothingNamed
    case notInThisBuild(String)

    var errorDescription: String? {
        switch self {
        case .noWorkingFolder:
            return "No working folder is open, so there is nothing to look at."
        case .noSuchCourse(let code):
            return "There is no course called “\(code)” in this working folder."
        case .noSuchSection(let code, let number):
            return "\(code) has no Section \(number)."
        case .noSuchPage(let title, let code, let number):
            return "No page in \(code) Section \(number) is called “\(title)”. "
                 + "Use list_pages to find its exact title."
        case .unreadablePage(let title):
            return "“\(title)” could not be read, so nothing was changed."
        case .noClassOn(let day, let code, let number):
            return "No class in \(code) Section \(number) is dated \(day.text), a \(day.weekdayName). "
                 + "Use list_pages to see what classes there are."
        case .unreadableDate(let raw, let which):
            return "“\(raw)” isn't a date \(which) can use. Give it as YYYY-MM-DD, for example 2026-09-15."
        case .unreadableTime(let raw):
            return "“\(raw)” isn't a time I can read. Use YYYY-MM-DD HH:MM, for example 2026-09-09 06:30."
        case .nothingNamed:
            return "No pages and no dates were given, so there is nothing to change."
        case .notInThisBuild(let what):
            return what
        }
    }

    /// The same words, never nil.
    var message: String {
        return errorDescription ?? "That could not be done."
    }
}
