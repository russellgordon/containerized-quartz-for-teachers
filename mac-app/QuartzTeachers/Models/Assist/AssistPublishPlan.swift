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

/// One page an unpublish reached by following a link and deliberately left
/// alone, and the reason it was left.
///
/// Said out loud in the plan, because "which pages did it NOT take down" is
/// exactly what a teacher wants to know: a concept page another class still
/// links to has to stay, or that other class is left pointing at nothing.
struct AssistPublishKept {

    // MARK: - Stored properties

    let page: AssistSectionPage

    /// The clause that finishes "“Ohm's Law” stays: …".
    let reason: String
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

    /// Pages an unpublish reached by following a link and left published, each
    /// with the reason. Always empty when publishing: publishing a page
    /// publishes everything it links to, with nothing held back.
    let kept: [AssistPublishKept]

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

        // The pages that STAY. Every one of them is a page a student can still
        // reach, and a teacher who is told only what came down has no way to
        // tell whether the tool thought about the rest.
        if !kept.isEmpty {
            lines.append("")
            let word: String = kept.count == 1 ? "page stays" : "pages stay"
            lines.append("\(kept.count) linked \(word) published:")
            var listed: Int = 0
            for staying in kept {
                if listed == mostListed {
                    lines.append("  …and \(kept.count - listed) more.")
                    break
                }
                lines.append("  \(staying.page.title)  —  \(staying.reason)")
                listed += 1
            }
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
///
/// **How far each verb reaches is settled HERE, not by whoever calls.** There
/// used to be an `includeLinked` flag, and the model chose it — which is
/// precisely the reasoning this design exists to keep out of a router. The two
/// rules are not mirror images of each other, and each is written down once:
///
/// * **Publishing always takes the pages it links to.** Publishing a page whose
///   links lead somewhere students cannot see is the one thing publishing must
///   never do.
/// * **Unpublishing takes a linked page only when nothing else needs it** — no
///   other page links to it, and it is not one of the pages a section cannot do
///   without. Hiding a concept page that Unit 3, Day 2 also links to would
///   break that class to tidy this one.
enum AssistPublishPlanner {

    // MARK: - Functions

    /// What publishing these pages would do — along with everything they link
    /// to, always, so no published page points at a page students cannot see.
    static func planPublishing(
        titles: [String],
        onOrAfter: CalendarDay?,
        before: CalendarDay?,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary],
        forSection sectionNumber: Int,
        in course: Course
    ) -> AssistPublishPlan {
        return plan(
            publishes: true, titles: titles,
            onOrAfter: onOrAfter, before: before, graph: graph, classPages: classPages,
            dateMoves: [], forSection: sectionNumber, in: course
        )
    }

    /// What unpublishing these pages would do — along with the pages ONLY they
    /// link to, and nothing else.
    static func planUnpublishing(
        titles: [String],
        onOrAfter: CalendarDay?,
        before: CalendarDay?,
        graph: AssistSectionGraph,
        classPages: [ClassPageSummary],
        forSection sectionNumber: Int,
        in course: Course
    ) -> AssistPublishPlan {
        return plan(
            publishes: false, titles: titles,
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
            publishes: true, titles: titles,
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

        // How far the verb reaches, decided by the verb itself.
        var linked: [AssistSectionPage] = []
        var kept: [AssistPublishKept] = []
        if publishes {
            linked = graph.linkedPages(from: named)
        } else {
            let sweep: UnpublishSweep = pagesTakenDownAlongside(
                named: named, graph: graph, in: course
            )
            linked = sweep.alsoUnpublished
            kept = sweep.kept
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
            kept: kept,
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

    // MARK: - How far an unpublish reaches

    /// What following an unpublish's links comes to: the pages that go with it,
    /// and the pages that stay, each with its reason.
    struct UnpublishSweep {

        // MARK: - Stored properties

        let alsoUnpublished: [AssistSectionPage]
        let kept: [AssistPublishKept]
    }

    /// The title of the panel every section carries, and whose entries are
    /// the section's way around itself.
    static let keyLinksTitle: String = "Key Links"

    /// The pages that come down alongside the ones the teacher named.
    ///
    /// The rule is deliberately NOT the mirror image of publishing. A linked
    /// page comes down only when the pages being taken down are the only ones
    /// that link to it; anything another page still points at stays, or hiding
    /// this week's lesson would leave last week's pointing at nothing.
    ///
    /// Three kinds of page never come down this way, whatever the link count:
    /// a folder's landing page (the way IN to a folder), anything the section's
    /// Key Links offers, and any curriculum page. Each is reached from
    /// somewhere other than a lesson, so a link count says nothing useful about
    /// whether it is still needed.
    ///
    /// Worked out to a fixed point rather than in one pass: when a page joins
    /// the ones coming down, the pages only IT linked to become free to follow
    /// as well, and stopping after one lap would leave half a chain published.
    static func pagesTakenDownAlongside(
        named: [AssistSectionPage],
        graph: AssistSectionGraph,
        in course: Course
    ) -> UnpublishSweep {
        var goingDown: Set<String> = []
        for page in named {
            goingDown.insert(page.lowercasedTitle)
        }

        let referrers: [String: [String]] = pagesLinkingIn(graph: graph)
        let mustStay: Set<String> = pagesThisSectionCannotDoWithout(graph: graph)

        var alsoUnpublished: [AssistSectionPage] = []
        var foundMore: Bool = true
        while foundMore {
            foundMore = false
            for candidate in pagesLinkedFrom(goingDown, graph: graph) {
                if goingDown.contains(candidate.lowercasedTitle) {
                    continue
                }
                let reason: String? = reasonToKeep(
                    candidate, mustStay: mustStay, referrers: referrers,
                    goingDown: goingDown, graph: graph, in: course
                )
                if reason != nil {
                    continue
                }
                goingDown.insert(candidate.lowercasedTitle)
                alsoUnpublished.append(candidate)
                foundMore = true
            }
        }

        var kept: [AssistPublishKept] = []
        for candidate in pagesLinkedFrom(goingDown, graph: graph) {
            // Only pages a student can see as things stand. A page already
            // hidden is not "staying published", and saying it is would be
            // noise in a plan meant to be read aloud.
            if !candidate.isVisibleToStudents {
                continue
            }
            guard let reason = reasonToKeep(
                candidate, mustStay: mustStay, referrers: referrers,
                goingDown: goingDown, graph: graph, in: course
            ) else {
                continue
            }
            kept.append(AssistPublishKept(page: candidate, reason: reason))
        }

        return UnpublishSweep(alsoUnpublished: alsoUnpublished, kept: kept)
    }

    /// Why this page is being left published, or nil when nothing stands in
    /// the way of taking it down with the rest.
    private static func reasonToKeep(
        _ page: AssistSectionPage,
        mustStay: Set<String>,
        referrers: [String: [String]],
        goingDown: Set<String>,
        graph: AssistSectionGraph,
        in course: Course
    ) -> String? {
        if page.isFolderIndex {
            return "it is a folder's landing page, which following links never takes down."
        }
        if mustStay.contains(page.lowercasedTitle) {
            return "it is in this section's Key Links."
        }
        // `build_site.py`'s own rule: any FOLDER segment containing
        // "curriculum", so a course whose folder is called "Ontario
        // Curriculum" is covered exactly as a plain one is.
        if AssistCurriculumMentions.isCurriculum(pageAt: page.fileURL, in: course) {
            return "it is a curriculum page."
        }
        if let stillLinking = pageStillLinking(to: page, referrers: referrers,
                                               goingDown: goingDown, graph: graph) {
            return "“\(stillLinking)” still links to it."
        }
        return nil
    }

    /// A page outside this unpublish that still links to the given one, named
    /// as the teacher would see it — or nil when the pages coming down are the
    /// only ones that point at it.
    private static func pageStillLinking(
        to page: AssistSectionPage,
        referrers: [String: [String]],
        goingDown: Set<String>,
        graph: AssistSectionGraph
    ) -> String? {
        for referrer in referrers[page.lowercasedTitle] ?? [] {
            if goingDown.contains(referrer) {
                continue
            }
            guard let linking = graph.page(titled: referrer) else {
                continue
            }
            return linking.title
        }
        return nil
    }

    /// Which pages link to each page, by lowercased title. A page linking to
    /// itself is not a reason to keep it.
    private static func pagesLinkingIn(graph: AssistSectionGraph) -> [String: [String]] {
        var referrers: [String: [String]] = [:]
        for page in graph.pages {
            for target in page.linkedTitles {
                if target == page.lowercasedTitle {
                    continue
                }
                var linking: [String] = referrers[target] ?? []
                if linking.contains(page.lowercasedTitle) {
                    continue
                }
                linking.append(page.lowercasedTitle)
                referrers[target] = linking
            }
        }
        return referrers
    }

    /// The pages a section cannot do without: everything its Key Links panel
    /// offers, and the panel itself.
    static func pagesThisSectionCannotDoWithout(graph: AssistSectionGraph) -> Set<String> {
        var titles: Set<String> = []
        guard let keyLinks = graph.page(titled: keyLinksTitle) else {
            return titles
        }
        titles.insert(keyLinks.lowercasedTitle)
        for target in keyLinks.linkedTitles {
            titles.insert(target)
        }
        return titles
    }

    /// The pages these ones link to, one hop out, leaving out the ones already
    /// counted in.
    private static func pagesLinkedFrom(
        _ titles: Set<String>,
        graph: AssistSectionGraph
    ) -> [AssistSectionPage] {
        var found: [AssistSectionPage] = []
        var seen: Set<String> = []
        for page in graph.pages where titles.contains(page.lowercasedTitle) {
            for target in page.linkedTitles {
                if titles.contains(target) || seen.contains(target) {
                    continue
                }
                guard let linked = graph.page(titled: target) else {
                    // A link out of this section, or to a page nobody wrote.
                    continue
                }
                seen.insert(target)
                found.append(linked)
            }
        }
        return found
    }

    // MARK: - Dates

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
    case openEndedPublish(CalendarDay)
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
        case .openEndedPublish(let day):
            return "That asks to publish every class from \(day.text) to the end of the course, which is "
                 + "almost certainly not what was meant. For ONE day's class, use publish_class_on with "
                 + "that date. For a stretch of classes, give both onOrAfter and before. To publish "
                 + "particular pages, name them."
        case .notInThisBuild(let what):
            return what
        }
    }

    /// The same words, never nil.
    var message: String {
        return errorDescription ?? "That could not be done."
    }
}
