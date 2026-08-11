import SwiftUI

/// The settings editor for one course: the same choices the setup wizard
/// offers, presented as a form. Save writes `course_config.json` — the file
/// the command-line scripts read — and Cancel reverts to the last save.
struct CourseSettingsView: View {

    // MARK: - Stored properties

    let course: Course

    @State var saveProblem: String?
    @State var didJustSave: Bool = false

    // MARK: - Body

    var body: some View {
        @Bindable var configuration = course.configuration

        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Course name", text: $configuration.courseName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("courseNameField")

                    if configuration.isClub {
                        TextField("Short label beside emoji (clubs, ≤ 12 characters)", text: $configuration.customShortName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("customShortNameField")
                    }

                    Picker("Language / region (Quartz locale)", selection: $configuration.locale) {
                        ForEach(LocaleCatalog.codes, id: \.self) { code in
                            Text(LocaleCatalog.displayName(forCode: code))
                                .tag(code)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Show the grade in the site title", isOn: $configuration.showGradeInTitle)
                            .accessibilityIdentifier("gradeInTitleToggle")
                        ExampleCaption("e.g. “Grade 12” before the course name — applied the next time each section builds")
                    }

                    Toggle("Show page read-time estimates to students", isOn: $configuration.showReadingTime)
                        .accessibilityIdentifier("readingTimeToggle")

                    Picker("Sidebar folders expand when clicking", selection: $configuration.expandOnFolderClick) {
                        Text("Chevron or folder name").tag(true)
                        Text("Chevron only (name opens the folder)").tag(false)
                    }
                } header: {
                    FormSectionHeader("Settings — Overall")
                }

                Section {
                    FooterEditorView(footerHTML: $configuration.footerHTML)
                } header: {
                    FormSectionHeader("Footer")
                }

                Section {
                    StringListEditorView(
                        title: "Shared folders (all sections)",
                        items: $configuration.sharedFolders
                    )
                    StringListEditorView(
                        title: "Shared files (all sections)",
                        hidesMarkdownExtension: true,
                        items: $configuration.sharedFiles
                    )
                    StringListEditorView(
                        title: "Per-section folders",
                        items: $configuration.perSectionFolders
                    )
                    StringListEditorView(
                        title: "Per-section files",
                        hidesMarkdownExtension: true,
                        items: $configuration.perSectionFiles
                    )
                    Text("Tip: you can also simply create new folders in Obsidian — they’re added to your site automatically the next time you preview.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } header: {
                    FormSectionHeader("Content Structure")
                }

                Section {
                    MembershipToggleListView(
                        title: "Hide from the site's sidebar",
                        allItems: configuration.allSidebarItems,
                        members: $configuration.hiddenItems
                    )
                    MembershipToggleListView(
                        title: "Expandable in the site's sidebar",
                        allItems: configuration.allSidebarItems,
                        members: $configuration.expandableItems
                    )
                } header: {
                    FormSectionHeader("Sidebar Visibility")
                }

                ForEach(course.sectionNumbers, id: \.self) { sectionNumber in
                    SectionSettingsView(
                        configuration: configuration,
                        sectionNumber: sectionNumber
                    )
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") {
                    try? course.configuration.discardChanges()
                }
                .disabled(!course.configuration.hasUnsavedChanges)
                .accessibilityIdentifier("cancelButton")

                Spacer()

                if let saveProblem {
                    Text(saveProblem)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                if didJustSave {
                    Text("Saved ✓")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .accessibilityIdentifier("savedConfirmation")
                }

                Button("Save") {
                    save()
                }
                .keyboardShortcut("s", modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(!course.configuration.hasUnsavedChanges)
                .accessibilityIdentifier("saveButton")
            }
            .padding(12)
        }
        .navigationTitle(course.code)
        .toolbar {
            ToolbarItem {
                Button("Open in Obsidian", systemImage: "square.and.pencil") {
                    FolderActions.openInObsidian(revealing: course.directoryURL, vaultURL: course.directoryURL)
                }
                .disabled(!FolderActions.obsidianIsInstalled)
                .help("Edit this course's pages in Obsidian")
                .accessibilityIdentifier("openCourseInObsidianButton")
            }
        }
        .navigationSubtitle(course.configuration.courseName)
    }

    // MARK: - Functions

    func save() {
        saveProblem = nil
        do {
            try course.configuration.write(to: course.configFileURL)
            didJustSave = true
            Task {
                try? await Task.sleep(for: .seconds(3))
                didJustSave = false
            }
        } catch {
            saveProblem = "Could not save: \(error.localizedDescription)"
        }
    }
}
