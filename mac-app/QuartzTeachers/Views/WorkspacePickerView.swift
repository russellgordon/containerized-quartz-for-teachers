import SwiftUI

/// Shown until a valid working folder has been chosen: explains what the
/// app needs and offers the folder picker.
struct WorkspacePickerView: View {

    // MARK: - Stored properties

    @Environment(WorkspaceModel.self) var workspace

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("Choose Your Working Folder")
                .font(.title2)
                .bold()

            Text("Pick the folder where your class websites live — the one with your courses inside (for example, “Class Websites” on your Desktop). Starting from scratch? Choose an empty folder instead.")
                .frame(maxWidth: 460)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let problem = workspace.workspaceProblem {
                Text(problem)
                    .frame(maxWidth: 460)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
            }

            if workspace.workspaceCanBeInitialized {
                if let chosenURL = workspace.workspaceURL {
                    FinderPathBarView(folderURL: chosenURL)
                        .frame(maxWidth: 520)
                }

                Text("This folder is empty. Set it up as your new working folder? Everything needed will be added for you, and you can create your first course right away.")
                    .frame(maxWidth: 460)
                    .multilineTextAlignment(.center)

                Button("Set Up This Folder") {
                    workspace.initializeWorkspace()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("initializeFolderButton")

                Button("Choose a Different Folder…") {
                    workspace.isChoosingWorkspace = true
                }
                .accessibilityIdentifier("chooseFolderButton")
            } else {
                Button("Choose Folder…") {
                    workspace.isChoosingWorkspace = true
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("chooseFolderButton")
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
