import Foundation

/// Whether students can see a page, and how to change that.
///
/// Which key carries the answer is decided by WHERE THE PAGE LIVES, exactly as
/// `PageFrontmatter` decides which key carries its date:
///
/// * a page inside `section<N>/` belongs to one section, so it carries a plain
///   `publish:`
/// * a course-level page is copied into every section at build time, so it
///   carries `publishForSection<N>:` — one flag per section
///
/// `draft:` and `draftSection<N>:` are the older spellings and mean the
/// OPPOSITE: `draft: true` is a page students cannot see. Both are read, and a
/// page written in the old spelling is written back in the old spelling,
/// inverted — respelling a teacher's frontmatter behind their back is a diff
/// nobody asked for, in a file Obsidian very likely has open.
///
/// A page that says nothing either way IS published. That is Quartz's own rule
/// here — `patches/publish.ts` drops a page only when it says `publish: false`
/// — and guessing the other way round would hide every page a teacher wrote
/// without thinking about frontmatter at all.
enum AssistPageVisibility {

    // MARK: - Functions

    /// The key that publishes this page in this section.
    static func publishKey(forSection sectionNumber: Int, isSectionLocal: Bool) -> String {
        return isSectionLocal ? "publish" : "publishForSection\(sectionNumber)"
    }

    /// The older key, which means the opposite.
    static func draftKey(forSection sectionNumber: Int, isSectionLocal: Bool) -> String {
        return isSectionLocal ? "draft" : "draftSection\(sectionNumber)"
    }

    /// The key this page actually uses, so a plan can name it to the teacher.
    static func keyInUse(in pageText: String, forSection sectionNumber: Int, isSectionLocal: Bool) -> String {
        let publish: String = publishKey(forSection: sectionNumber, isSectionLocal: isSectionLocal)
        if PageFrontmatter.rawValue(forKey: publish, in: pageText) != nil {
            return publish
        }
        let draft: String = draftKey(forSection: sectionNumber, isSectionLocal: isSectionLocal)
        if PageFrontmatter.rawValue(forKey: draft, in: pageText) != nil {
            return draft
        }
        return publish
    }

    /// Whether this section publishes this page, or nil when the page says
    /// nothing either way.
    ///
    /// Course-level pages go through `SectionAdder.publishValue(forSection:in:)`
    /// — the same reader that carries visibility across when a section is
    /// added, so the two can never disagree about what `draftSection2: true`
    /// meant.
    static func statedPublishing(
        in pageText: String,
        forSection sectionNumber: Int,
        isSectionLocal: Bool
    ) -> Bool? {
        if !isSectionLocal {
            guard let block = PageFrontmatter.block(in: pageText) else {
                return nil
            }
            var lines: [String] = []
            for line in block.lines {
                lines.append(PageFrontmatter.trimmingCarriageReturn(line))
            }
            guard let value = SectionAdder.publishValue(forSection: sectionNumber, in: lines) else {
                return nil
            }
            return isTrue(value)
        }

        if let value = PageFrontmatter.rawValue(forKey: "publish", in: pageText) {
            return isTrue(value)
        }
        if let value = PageFrontmatter.rawValue(forKey: "draft", in: pageText) {
            return !isTrue(value)
        }
        return nil
    }

    /// Whether students meet this page, with Quartz's own default applied to a
    /// page that says nothing.
    static func publishes(
        in pageText: String,
        forSection sectionNumber: Int,
        isSectionLocal: Bool
    ) -> Bool {
        return statedPublishing(
            in: pageText, forSection: sectionNumber, isSectionLocal: isSectionLocal
        ) ?? true
    }

    /// The page text with this section's visibility set, and whether that
    /// changed anything.
    ///
    /// A line-level edit, for the reason `PageFrontmatter` gives: the
    /// teacher's frontmatter is theirs, and round-tripping it through a YAML
    /// library would reorder keys and strip their comments.
    static func setting(
        published: Bool,
        in pageText: String,
        forSection sectionNumber: Int,
        isSectionLocal: Bool
    ) -> (text: String, changed: Bool) {
        let key: String = keyInUse(
            in: pageText, forSection: sectionNumber, isSectionLocal: isSectionLocal
        )
        // A page written in the old spelling keeps it, inverted: `draft` is
        // "students cannot see this", so publishing means `draft: false`.
        let isDraftKey: Bool = key == draftKey(forSection: sectionNumber, isSectionLocal: isSectionLocal)
        let value: String = (isDraftKey ? !published : published) ? "true" : "false"

        let existing: String? = PageFrontmatter.rawValue(forKey: key, in: pageText)
        if let existing, existing == value {
            return (pageText, false)
        }

        let line: String = key + ": " + value
        guard let block = PageFrontmatter.block(in: pageText) else {
            // No frontmatter at all: give the page a block of its own, the
            // way `PageFrontmatter.settingCreated` does.
            return ("---\n" + line + "\n---\n" + pageText, true)
        }

        var lines: [String] = pageText.components(separatedBy: "\n")
        let prefix: String = key + ":"
        for index in (block.openIndex + 1)..<block.closeIndex {
            if PageFrontmatter.trimmingCarriageReturn(lines[index]).hasPrefix(prefix) {
                lines[index] = line + (lines[index].hasSuffix("\r") ? "\r" : "")
                return (lines.joined(separator: "\n"), true)
            }
        }
        lines.insert(line, at: block.openIndex + 1)
        return (lines.joined(separator: "\n"), true)
    }

    /// True when this page lives in one section's own folder, and so carries
    /// the plain keys rather than the per-section ones.
    static func isSectionLocal(pageAt url: URL, forSection sectionNumber: Int, in course: Course) -> Bool {
        let folder: String = course.sectionDirectoryURL(forSection: sectionNumber)
            .standardizedFileURL.path
        let page: String = url.standardizedFileURL.path
        return page.hasPrefix(folder + "/")
    }

    /// YAML's spelling of yes, as the toolchain reads it.
    static func isTrue(_ value: String) -> Bool {
        let tidied: String = value
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            .lowercased()
        return tidied == "true" || tidied == "yes"
    }
}
