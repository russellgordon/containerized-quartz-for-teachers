import Foundation

/// One page of a section, as the tools see it.
struct AssistSectionPage {

    // MARK: - Stored properties

    /// The file name without `.md` — which is also the name links use.
    let title: String

    let fileURL: URL

    /// The path a teacher would recognise, relative to the working folder.
    let relativePath: String

    /// True when the page lives in this section's own folder.
    let isSectionLocal: Bool

    /// True when students meet this page as things stand.
    let isVisibleToStudents: Bool

    /// The day the page's frontmatter puts it on, or nil when it has none.
    let date: CalendarDay?

    /// The pages this one links to, lowercased, as wikilink targets.
    let linkedTitles: [String]

    // MARK: - Computed properties

    /// A folder's landing page. Never a lesson, and never an orphan: it is the
    /// way IN to a folder rather than a page anything links to.
    var isFolderIndex: Bool {
        return fileURL.lastPathComponent.lowercased() == "index.md"
    }

    var lowercasedTitle: String {
        return title.lowercased()
    }
}

/// A link on one page that leads to another.
struct AssistSectionLink {

    // MARK: - Stored properties

    let fromRelativePath: String
    let toTitle: String
}

/// Every page in one section, what links to what, and who can see it.
///
/// Built by reading the files, once, so that every tool that needs to follow a
/// link — publishing a class along with what it uses, checking what students
/// would meet — works from the same picture rather than each walking the folder
/// its own way.
struct AssistSectionGraph {

    // MARK: - Stored properties

    let courseCode: String
    let sectionNumber: Int
    let pages: [AssistSectionPage]

    /// Every page by its lowercased title, so a link resolves the way Obsidian
    /// resolves it — without regard to case.
    private let pagesByTitle: [String: AssistSectionPage]

    // MARK: - Computed properties

    var visiblePageCount: Int {
        var count: Int = 0
        for page in pages {
            if page.isVisibleToStudents {
                count += 1
            }
        }
        return count
    }

    // MARK: - Initializer

    init(courseCode: String, sectionNumber: Int, pages: [AssistSectionPage]) {
        self.courseCode = courseCode
        self.sectionNumber = sectionNumber
        self.pages = pages

        var byTitle: [String: AssistSectionPage] = [:]
        for page in pages {
            // First one wins, and pages arrive in path order, so the answer is
            // the same every time two folders hold a page of the same name.
            if byTitle[page.lowercasedTitle] == nil {
                byTitle[page.lowercasedTitle] = page
            }
        }
        pagesByTitle = byTitle
    }

    // MARK: - Functions

    /// Read one section's pages off disk.
    static func read(forSection sectionNumber: Int, in course: Course, workspaceURL: URL?) -> AssistSectionGraph {
        var pages: [AssistSectionPage] = []
        for pageURL in ClassPages.pagesOfSection(sectionNumber, in: course) {
            guard let text = try? String(contentsOf: pageURL, encoding: .utf8) else {
                continue
            }
            let isSectionLocal: Bool = AssistPageVisibility.isSectionLocal(
                pageAt: pageURL, forSection: sectionNumber, in: course
            )
            let dateKey: String = PageFrontmatter.createdKey(
                forSection: sectionNumber, isSectionLocal: isSectionLocal
            )
            pages.append(AssistSectionPage(
                title: pageURL.deletingPathExtension().lastPathComponent,
                fileURL: pageURL,
                relativePath: relativePath(of: pageURL, workspaceURL: workspaceURL),
                isSectionLocal: isSectionLocal,
                isVisibleToStudents: AssistPageVisibility.publishes(
                    in: text, forSection: sectionNumber, isSectionLocal: isSectionLocal
                ),
                date: PageFrontmatter.createdDay(in: text, key: dateKey),
                linkedTitles: linkTargets(in: text)
            ))
        }
        return AssistSectionGraph(courseCode: course.code, sectionNumber: sectionNumber, pages: pages)
    }

    /// The page with this title, however it was capitalised, and whether or not
    /// the teacher wrote the folder in front of it.
    func page(titled title: String) -> AssistSectionPage? {
        let tidied: String = normalized(title)
        if tidied.isEmpty {
            return nil
        }
        return pagesByTitle[tidied]
    }

    /// The pages these ones link to, and the pages THOSE link to, and so on.
    ///
    /// Transitive on purpose. "Publish tomorrow's class and everything it links
    /// to" means the concept page the class points at AND the snippet that
    /// concept page points at; stopping at one hop leaves a student one click
    /// from nothing.
    func linkedPages(from starting: [AssistSectionPage]) -> [AssistSectionPage] {
        var seen: Set<String> = []
        for page in starting {
            seen.insert(page.lowercasedTitle)
        }

        var found: [AssistSectionPage] = []
        var queue: [AssistSectionPage] = starting
        while !queue.isEmpty {
            let page: AssistSectionPage = queue.removeFirst()
            for target in page.linkedTitles {
                if seen.contains(target) {
                    continue
                }
                seen.insert(target)
                guard let linked = pagesByTitle[target] else {
                    // A link to something outside this section, or to a page
                    // that does not exist. Not this tool's business to invent.
                    continue
                }
                found.append(linked)
                queue.append(linked)
            }
        }
        return found
    }

    /// Links a student could click on a page they can see, that lead to a page
    /// they cannot.
    func linksIntoHiddenPages() -> [AssistSectionLink] {
        var dangling: [AssistSectionLink] = []
        for page in pages {
            if !page.isVisibleToStudents {
                continue
            }
            var alreadyReported: Set<String> = []
            for target in page.linkedTitles {
                guard let destination = pagesByTitle[target], !destination.isVisibleToStudents else {
                    continue
                }
                if alreadyReported.contains(target) {
                    continue
                }
                alreadyReported.insert(target)
                dangling.append(AssistSectionLink(
                    fromRelativePath: page.relativePath, toTitle: destination.title
                ))
            }
        }
        return dangling
    }

    /// Visible pages nothing links to.
    ///
    /// These are the pages no publish or hide rule that follows links will ever
    /// reach, and students find them anyway through the site's explorer. Folder
    /// landing pages are left out: an `index.md` is the way in to a folder, not
    /// a page anybody was ever going to link to.
    func visiblePagesNothingLinksTo() -> [AssistSectionPage] {
        var linkedFromSomewhere: Set<String> = []
        for page in pages {
            for target in page.linkedTitles {
                linkedFromSomewhere.insert(target)
            }
        }

        var orphans: [AssistSectionPage] = []
        for page in pages {
            if !page.isVisibleToStudents || page.isFolderIndex {
                continue
            }
            if linkedFromSomewhere.contains(page.lowercasedTitle) {
                continue
            }
            orphans.append(page)
        }
        return orphans
    }

    /// Every wikilink target on a page, lowercased.
    ///
    /// The pattern is `WikiLinkRewriter`'s own, so a link this reads is exactly
    /// a link a rename would rewrite — one definition of "a link", not two.
    static func linkTargets(in text: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: WikiLinkRewriter.pattern) else {
            return []
        }
        let whole: NSRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var targets: [String] = []
        var seen: Set<String> = []
        for match in expression.matches(in: text, range: whole) {
            guard let targetRange = Range(match.range(at: 2), in: text) else {
                continue
            }
            let target: String = normalized(String(text[targetRange]))
            if target.isEmpty || seen.contains(target) {
                continue
            }
            seen.insert(target)
            targets.append(target)
        }
        return targets
    }

    /// A link target or a teacher's page name reduced to the form the index
    /// uses: no folder in front, no `.md` on the end, no case.
    static func normalized(_ name: String) -> String {
        var tidied: String = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lastSlash = tidied.lastIndex(of: "/") {
            tidied = String(tidied[tidied.index(after: lastSlash)...])
        }
        if tidied.lowercased().hasSuffix(".md") {
            tidied = String(tidied.dropLast(3))
        }
        return tidied.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private func normalized(_ name: String) -> String {
        return AssistSectionGraph.normalized(name)
    }

    /// Where a page sits, said the way a teacher would say it.
    static func relativePath(of url: URL, workspaceURL: URL?) -> String {
        let full: String = url.standardizedFileURL.path
        guard let workspaceURL else {
            return full
        }
        let root: String = workspaceURL.standardizedFileURL.path + "/"
        if full.hasPrefix(root) {
            return String(full.dropFirst(root.count))
        }
        return full
    }
}
