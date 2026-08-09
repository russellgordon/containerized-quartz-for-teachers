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

            Text("Pick the folder you use with the command-line toolchain — the one containing setup.sh, preview.sh, deploy.sh, and your courses folder (for example, “Class Websites” on your Desktop).")
                .frame(maxWidth: 460)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let problem = workspace.workspaceProblem {
                Text(problem)
                    .frame(maxWidth: 460)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
            }

            Button("Choose Folder…") {
                workspace.isChoosingWorkspace = true
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("chooseFolderButton")
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
