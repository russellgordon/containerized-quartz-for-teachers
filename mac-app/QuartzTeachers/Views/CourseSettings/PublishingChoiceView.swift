import AppKit
import SwiftUI

/// The publishing choice — Netlify, or a folder on this Mac — used by both
/// Course Settings and the new-course wizard, so the two offer exactly the
/// same behaviour and wording.
struct PublishingChoiceView: View {

    // MARK: - Stored properties

    @Binding var deployTarget: String
    @Binding var deployFolderPath: String

    // MARK: - Computed properties

    /// What is wrong with the chosen folder, or nil when nothing is.
    var folderProblem: String? {
        if deployTarget != "local_folder" {
            return nil
        }
        return CourseConfiguration.deployFolderProblem(forPath: deployFolderPath)
    }

    // MARK: - Body

    var body: some View {
        Picker("Publish to", selection: $deployTarget) {
            Text("Netlify").tag("netlify")
            Text("A folder on this Mac").tag("local_folder")
        }
        .accessibilityIdentifier("deployTargetPicker")

        if deployTarget == "local_folder" {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Folder", text: $deployFolderPath)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("deployFolderField")
                    Button("Choose…") {
                        chooseDeployFolder()
                    }
                    .accessibilityIdentifier("deployFolderChooseButton")
                }
                if let folderProblem {
                    // The same orange every other inline warning wears.
                    Text(folderProblem)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("deployFolderProblem")
                } else {
                    ExampleCaption("Each section publishes into its own subfolder here — section1, section2 — and only changed files are copied. Upload the folder to your web host however you prefer (e.g. over SFTP). Netlify isn’t involved.")
                }
            }
        }
    }

    // MARK: - Functions

    /// The standard folder chooser, writing straight into the setting.
    func chooseDeployFolder() {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose the folder this course's sections publish into."
        if panel.runModal() == .OK, let chosen = panel.url {
            deployFolderPath = chosen.path
        }
    }
}
