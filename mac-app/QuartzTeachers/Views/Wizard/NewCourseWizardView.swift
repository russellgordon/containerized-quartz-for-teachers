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
                    ExampleCaption("e.g. 1,3 — comma-separated")
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
                Picker("Header emoji", selection: $emoji) {
                    ForEach(EmojiCatalog.presets, id: \.self) { presetEmoji in
                        Text(presetEmoji).tag(presetEmoji)
                    }
                }
                ColourSchemePickerView(selectedSchemeID: $colourSchemeID)
                FontChoiceEditorView(choice: $fontChoice)
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show section marker in the site title", isOn: $showsSectionMarker)
                    ExampleCaption("e.g. “S1” appears beside the course code")
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
                // The lists are long, so they stay collapsed until needed.
                DisclosureGroup("Folders and files") {
                    StringListEditorView(title: "Shared folders", items: $sharedFolders)
                    StringListEditorView(title: "Shared files", hidesMarkdownExtension: true, items: $sharedFiles)
                    StringListEditorView(title: "Per-section folders", items: $perSectionFolders)
                    StringListEditorView(title: "Per-section files", hidesMarkdownExtension: true, items: $perSectionFiles)
                }
                .accessibilityIdentifier("structureDisclosure")
            } header: {
                FormSectionHeader("Structure", caption: "Defaults are fine for most courses")
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
        if parsedSectionNumbers.isEmpty {
            validationProblem = "Enter at least one section number (e.g. 1)."
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
        var schemeMap: [String: String] = [:]
        var fontsSectionsMap: [String: Any] = [:]
        for sectionNumber in sectionNumbers {
            let key: String = "section\(sectionNumber)"
            emojiMap[key] = emoji
            markerMap[key] = showsSectionMarker
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
            "fonts": [
                "default": fontChoice.dictionaryRepresentation,
                "sections": fontsSectionsMap,
            ],
            "show_section_marker": ["sections": markerMap],
            "color_schemes": schemeMap,
        ]
    }
}
