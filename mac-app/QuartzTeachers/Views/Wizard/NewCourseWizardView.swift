import SwiftUI

/// Collects the same answers the command-line setup wizard asks for, then
/// creates the course by running the real `./setup.sh` (see
/// `NewCourseCreator`). Progress streams into a console at the bottom.
struct NewCourseWizardView: View {

    // MARK: - Stored properties

    @Environment(WorkspaceModel.self) var workspace
    @Environment(\.dismiss) var dismiss

    @State var creator = NewCourseCreator()

    @State var courseCode: String = ""
    @State var courseName: String = ""

    /// The last name this view filled in automatically. Auto-fill only
    /// ever replaces its own suggestion, never a name the teacher typed.
    @State var lastAutoFilledName: String = ""
    @State var customShortName: String = ""
    @State var locale: String = "en-US"
    @State var sectionNumbersText: String = "1"
    @State var emoji: String = "📚"
    @State var colourSchemeID: String = "quartz-standard"
    @State var showsSectionMarker: Bool = true

    /// Whether the site title leads with the grade ("Grade 12 …").
    @State var showsGradeInTitle: Bool = true

    /// Whether the new course starts with the ready-made example content
    /// written for its course code (when the app has some).
    @State var prepopulatesExampleContent: Bool = true

    /// Whether the example content brings the official curriculum pages
    /// along with it.
    @State var includesCurriculumPages: Bool = true

    /// Whether the factory structure uses LCS's own words and folders
    /// (Grove Time, SIC, College Board Curriculum) instead of the
    /// school-neutral defaults.
    @State var usesLCSTerminology: Bool = false
    @State var fontChoice: FontChoice = FontChoice.systemDefault
    @State var expandOnFolderClick: Bool = false
    @State var showReadingTime: Bool = false
    @State var footerHTML: String = ""

    @State var sharedFolders: [String] = WizardDefaults.sharedFolders
    @State var sharedFiles: [String] = WizardDefaults.sharedFiles
    @State var perSectionFolders: [String] = WizardDefaults.perSectionFolders
    @State var perSectionFiles: [String] = WizardDefaults.perSectionFiles

    @State var validationProblem: String?
    @State var hasStarted: Bool = false

    /// What the progress header is called — the wizard creates a course,
    /// but the same sheet also adds the example course.
    @State var progressTitle: String = "Creating your course"

    // MARK: - Initializer

    init(creator: NewCourseCreator = NewCourseCreator(), startedForTesting: Bool = false) {
        _creator = State(initialValue: creator)
        if startedForTesting {
            _hasStarted = State(initialValue: true)
        }
    }

    // MARK: - Computed properties

    /// The parsed timetable section numbers, e.g. "1,3" → [1, 3].
    /// What is wrong with the timetable sections as typed, or nil when
    /// nothing is. Written for the mistakes people actually make, and it
    /// matters beyond politeness: the parser silently DROPS pieces it
    /// cannot read, so "1,3 5" would quietly become just section 1.
    static func sectionNumbersProblem(_ text: String) -> String? {
        let trimmed: String = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Enter at least one section number — e.g. 1, or 1,3."
        }

        var seen: [Int] = []
        for rawPart in trimmed.components(separatedBy: ",") {
            let part: String = rawPart.trimmingCharacters(in: .whitespaces)
            if part.isEmpty {
                return "There’s an empty spot between commas."
            }
            if let number = Int(part) {
                if number < 1 {
                    // Careful wording: a teacher may well teach only
                    // sections 2, 4, and 5 of a course — nothing requires
                    // the list to include 1, only that each number is one.
                    return "“\(part)” isn’t a section number — sections are 1 or higher."
                }
                if seen.contains(number) {
                    return "Section \(number) is listed more than once."
                }
                seen.append(number)
                continue
            }
            // "1 3 5": every space-separated piece is a number, so the
            // separators are what went wrong.
            var allPiecesAreNumbers: Bool = true
            for piece in part.split(separator: " ") {
                if Int(piece) == nil {
                    allPiecesAreNumbers = false
                }
            }
            if allPiecesAreNumbers && part.contains(" ") {
                return "Use commas between section numbers — e.g. \(part.split(separator: " ").joined(separator: ","))."
            }
            return "“\(part)” isn’t a section number — sections are whole numbers, like 1 or 3."
        }
        return nil
    }

    /// The problem with the sections as typed, live.
    var sectionNumbersProblem: String? {
        return NewCourseWizardView.sectionNumbersProblem(sectionNumbersText)
    }

    /// True when the example content, not the teacher, decides the
    /// course's folders and files — the pages were written for one exact
    /// layout, and a hand-edited structure would strand their links.
    var structureComesFromExampleContent: Bool {
        return prepopulatesExampleContent
            && ExampleContentCatalog.hasContent(forCode: courseCode)
    }

    var parsedSectionNumbers: [Int] {
        var result: [Int] = []
        let parts: [String] = sectionNumbersText.components(separatedBy: ",")
        for part in parts {
            let trimmed: String = part.trimmingCharacters(in: .whitespaces)
            if let number = Int(trimmed) {
                if number > 0 && !result.contains(number) {
                    result.append(number)
                }
            }
        }
        return result
    }

    var isClubCode: Bool {
        let code: String = courseCode.trimmingCharacters(in: .whitespaces)
        if code.count < 4 {
            return false
        }
        let characters: [Character] = Array(code)
        return !characters[3].isNumber
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Course or Club")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            .padding()

            if hasStarted {
                TaskProgressView(runner: creator.runner, title: progressTitle)
                Spacer(minLength: 0)
            } else {
                exampleCourseInvitation
                wizardForm
            }

            Divider()

            HStack {
                // Cancel lives bottom-left while there is something to
                // cancel; the affirmative action (Create Course / Done)
                // is always bottom-right, per macOS convention.
                if !hasStarted || creator.isCreating {
                    Button("Cancel") {
                        if creator.isCreating {
                            creator.runner.terminate()
                        }
                        workspace.reloadCourses()
                        dismiss()
                    }
                    .accessibilityIdentifier("wizardCloseButton")
                }

                Spacer()

                if let validationProblem {
                    Text(validationProblem)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                if let problem = creator.preparationProblem {
                    Text(problem)
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                if !hasStarted {
                    Button("Create Course") {
                        startCreation()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("createCourseButton")
                } else {
                    // Present throughout so the footer never reflows;
                    // enabled (and the default action) once work ends.
                    Button("Close") {
                        workspace.reloadCourses()
                        // Land the teacher inside what was just made,
                        // rather than back at an empty window.
                        if let exampleCode = creator.installedExampleCode {
                            workspace.selection = SidebarSelection.section(exampleCode, 1)
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(creator.isCreating)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("wizardCloseActionButton")
                }
            }
            .padding(12)
        }
        .frame(width: 680, height: 620)
        .interactiveDismissDisabled(creator.isCreating)
    }

    var wizardForm: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Course code", text: $courseCode)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("wizardCourseCodeField")
                        .onChange(of: courseCode) {
                            autoFillCourseName()
                        }
                    ExampleCaption("e.g. ICS3U — or a club name like CODING")
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Course name", text: $courseName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("wizardCourseNameField")
                    ExampleCaption("e.g. Introduction to Computer Science")
                }

                // For known Ontario course codes, offer the same formal and
                // short names the command-line wizard suggests.
                if let knownNames = CourseNameCatalog.names(forCode: courseCode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested names for \(courseCode.trimmingCharacters(in: .whitespaces).uppercased()):")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button(knownNames.formal) {
                                courseName = knownNames.formal
                                lastAutoFilledName = knownNames.formal
                            }
                            .accessibilityIdentifier("suggestedFormalNameButton")
                            Button(knownNames.short) {
                                courseName = knownNames.short
                                lastAutoFilledName = knownNames.short
                            }
                            .accessibilityIdentifier("suggestedShortNameButton")
                        }
                        .font(.callout)
                    }
                }
                if isClubCode {
                    TextField("Short label beside emoji (≤ 12 characters)", text: $customShortName)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Timetable section numbers", text: $sectionNumbersText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("wizardSectionNumbersField")
                    if let problem = sectionNumbersProblem {
                        // The same orange every other warning wears.
                        Text(problem)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("sectionNumbersWarning")
                    } else {
                        ExampleCaption("e.g. 1,3 — comma-separated")
                    }
                }
                Picker("Language / region", selection: $locale) {
                    ForEach(LocaleCatalog.codes, id: \.self) { code in
                        Text(LocaleCatalog.displayName(forCode: code)).tag(code)
                    }
                }
            } header: {
                FormSectionHeader("Basics")
            }

            Section {
                if ExampleContentCatalog.hasContent(forCode: courseCode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Pre-populate course with example content", isOn: $prepopulatesExampleContent)
                            .accessibilityIdentifier("prepopulateToggle")
                        ExampleCaption("Working pages written for this course — keep, edit, or delete them as you build your own site. The example content also chooses the course's folders and files, so they fit the pages.")
                    }
                    if ExampleContentCatalog.includesCurriculum(forCode: courseCode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Include Ontario curriculum pages", isOn: $includesCurriculumPages)
                                .disabled(!prepopulatesExampleContent)
                                .accessibilityIdentifier("curriculumToggle")
                            ExampleCaption("Every expectation as its own page, so lessons and tasks can link to exactly what they address")
                        }
                    }
                } else {
                    Text("Example content isn’t available for this course code yet, so the course will start with empty folders ready for your own pages.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("noExampleContentNote")
                }
            } header: {
                FormSectionHeader("Starting Content")
            }

            Section {
                EmojiChoiceField(label: "Header emoji", emoji: $emoji)
                ColourSchemePickerView(selectedSchemeID: $colourSchemeID)
                FontChoiceEditorView(choice: $fontChoice)
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show section marker in the site title", isOn: $showsSectionMarker)
                    ExampleCaption("e.g. “S1” appears beside the course code")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show the grade in the site title", isOn: $showsGradeInTitle)
                    if let warning = CourseConfiguration.gradeInTitleWarning(
                        courseName: courseName,
                        courseCode: courseCode.trimmingCharacters(in: .whitespaces).uppercased(),
                        showsGrade: showsGradeInTitle
                    ) {
                        Text(warning)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("wizardGradeInTitleWarning")
                    } else {
                        ExampleCaption("e.g. “Grade 12” before the course name")
                    }
                }
            } header: {
                FormSectionHeader("Appearance", caption: "Applied to every section — fine-tune later in Settings")
            }

            Section {
                Picker("Sidebar folders expand when clicking", selection: $expandOnFolderClick) {
                    Text("Chevron or folder name").tag(true)
                    Text("Chevron only (name opens the folder)").tag(false)
                }
                Toggle("Show page read-time estimates to students", isOn: $showReadingTime)
            } header: {
                FormSectionHeader("Behaviour")
            }

            Section {
                if structureComesFromExampleContent {
                    Text("The example content chooses the folders and files for this course, so every page lands where its links expect it. Turn off pre-populating to choose your own structure.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("structureFromExampleNote")
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Use LCS-specific terminology", isOn: $usesLCSTerminology)
                            .accessibilityIdentifier("lcsTerminologyToggle")
                        ExampleCaption("e.g. “Grove Time” instead of “Extra Help”, plus the College Board Curriculum folder")
                    }
                    .onChange(of: usesLCSTerminology) { wasLCS, isLCS in
                        sharedFolders = WizardDefaults.switchingFactoryItems(
                            in: sharedFolders,
                            toFactory: isLCS ? WizardDefaults.lcsSharedFolders : WizardDefaults.sharedFolders,
                            fromFactory: wasLCS ? WizardDefaults.lcsSharedFolders : WizardDefaults.sharedFolders
                        )
                        sharedFiles = WizardDefaults.switchingFactoryItems(
                            in: sharedFiles,
                            toFactory: isLCS ? WizardDefaults.lcsSharedFiles : WizardDefaults.sharedFiles,
                            fromFactory: wasLCS ? WizardDefaults.lcsSharedFiles : WizardDefaults.sharedFiles
                        )
                    }

                    // The lists are long, so they stay collapsed until needed.
                    DisclosureGroup("Folders and files") {
                        StringListEditorView(title: "Shared folders", items: $sharedFolders)
                        StringListEditorView(title: "Shared files", hidesMarkdownExtension: true, items: $sharedFiles)
                        StringListEditorView(title: "Per-section folders", items: $perSectionFolders)
                        StringListEditorView(title: "Per-section files", hidesMarkdownExtension: true, items: $perSectionFiles)
                    }
                    .accessibilityIdentifier("structureDisclosure")
                }
            } header: {
                if structureComesFromExampleContent {
                    FormSectionHeader("Structure", caption: "Chosen by the example content")
                } else {
                    FormSectionHeader("Structure", caption: "Defaults are fine for most courses")
                }
            }

            Section {
                FooterEditorView(footerHTML: $footerHTML)
            } header: {
                FormSectionHeader("Footer")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Functions

    /// When a known course code is entered, pre-fill the name with the
    /// formal name — but only if the name field is empty or still holds a
    /// previous auto-fill, so a teacher's own typing is never replaced.
    func autoFillCourseName() {
        guard let knownNames = CourseNameCatalog.names(forCode: courseCode) else {
            return
        }
        let mayReplace: Bool = courseName.isEmpty || courseName == lastAutoFilledName
        if mayReplace {
            courseName = knownNames.formal
            lastAutoFilledName = knownNames.formal
        }
    }

    /// Offered above the form: someone who has never built a course learns
    /// far more from opening a finished one than from an empty form.
    var exampleCourseInvitation: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("New to this?")
                    .font(.headline)
                Text("Add a complete example course — a real Grade 9 science course you can explore, change, and remove whenever you like.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Button("Add Example Course") {
                startExampleInstall()
            }
            .accessibilityIdentifier("addExampleCourseButton")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    // MARK: - Functions

    /// Adds the example course. Nothing else on this form is needed for it.
    func startExampleInstall() {
        validationProblem = nil
        guard let workspaceURL = workspace.workspaceURL else {
            validationProblem = "Choose a working folder first."
            return
        }
        progressTitle = "Adding the example course"
        hasStarted = true
        creator.installExampleCourse(workspaceURL: workspaceURL)
    }

    func startCreation() {
        validationProblem = nil

        let code: String = courseCode.trimmingCharacters(in: .whitespaces).uppercased()
        if code.isEmpty || code.contains(" ") {
            validationProblem = "Enter a course code without spaces."
            return
        }
        if let problem = NewCourseWizardView.sectionNumbersProblem(sectionNumbersText) {
            validationProblem = problem
            return
        }
        for existingCourse in workspace.courses {
            if existingCourse.code == code {
                validationProblem = "A course named \(code) already exists."
                return
            }
        }
        guard let workspaceURL = workspace.workspaceURL else {
            validationProblem = "No working folder is selected."
            return
        }

        var name: String = courseName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            name = "Course Website"
        }

        hasStarted = true
        creator.createCourse(
            configuration: buildConfigurationDictionary(code: code, name: name),
            workspaceURL: workspaceURL
        )
    }

    /// Assembles the same JSON shape the setup wizard saves, which the
    /// wizard then re-reads as its defaults when the app runs it.
    func buildConfigurationDictionary(code: String, name: String) -> [String: Any] {
        let sectionNumbers: [Int] = parsedSectionNumbers

        var emojiMap: [String: String] = [:]
        var markerMap: [String: Bool] = [:]
        var gradeMap: [String: Bool] = [:]
        var schemeMap: [String: String] = [:]
        var fontsSectionsMap: [String: Any] = [:]
        for sectionNumber in sectionNumbers {
            let key: String = "section\(sectionNumber)"
            emojiMap[key] = emoji
            markerMap[key] = showsSectionMarker
            gradeMap[key] = showsGradeInTitle
            schemeMap[key] = colourSchemeID
            fontsSectionsMap[key] = fontChoice.dictionaryRepresentation
        }

        var hiddenItems: [String] = []
        for item in WizardDefaults.hiddenItems {
            let isKnown: Bool = sharedFolders.contains(item)
                || sharedFiles.contains(item)
                || perSectionFolders.contains(item)
                || perSectionFiles.contains(item)
                || item == "Media"
            if isKnown {
                hiddenItems.append(item)
            }
        }

        var expandableItems: [String] = []
        for item in WizardDefaults.expandableItems {
            if sharedFolders.contains(item) || perSectionFolders.contains(item) {
                expandableItems.append(item)
            }
        }

        return [
            "course_code": code,
            "course_name": name,
            "custom_short_name": isClubCode ? customShortName.trimmingCharacters(in: .whitespaces) : "",
            "locale": locale,
            "emojis": ["sections": emojiMap],
            "num_sections": sectionNumbers.count,
            "section_numbers": sectionNumbers,
            "shared_folders": sharedFolders,
            "shared_files": sharedFiles,
            "per_section_folders": perSectionFolders,
            "per_section_files": perSectionFiles,
            "hidden": hiddenItems,
            "expandable": expandableItems,
            "expandOnFolderClick": expandOnFolderClick,
            "footer_html": footerHTML,
            "show_reading_time": showReadingTime,
            "show_grade_in_title": ["sections": gradeMap],
            // The real wizard reads these as its defaults, exactly like
            // every other answer here. False when no content exists for
            // the code, so a stale true can never mean anything.
            "prepopulate_example_content": ExampleContentCatalog.hasContent(forCode: code)
                && prepopulatesExampleContent,
            "include_curriculum_pages": ExampleContentCatalog.hasContent(forCode: code)
                && prepopulatesExampleContent
                && ExampleContentCatalog.includesCurriculum(forCode: code)
                && includesCurriculumPages,
            "use_lcs_terminology": usesLCSTerminology,
            "fonts": [
                "default": fontChoice.dictionaryRepresentation,
                "sections": fontsSectionsMap,
            ],
            "show_section_marker": ["sections": markerMap],
            "color_schemes": schemeMap,
        ]
    }
}
