import AppKit
import SwiftUI

/// The deploy destination — Netlify, Cloudflare Pages, or a folder on this
/// Mac — used by both Course Settings and the new-course wizard, so the two
/// offer exactly the same behaviour and wording.
struct PublishingChoiceView: View {

    // MARK: - Stored properties

    @Binding var deployTarget: String
    @Binding var deployFolderPath: String

    /// The teacher's Cloudflare Account ID. It lives in app settings, not
    /// in this course's settings — it identifies the person, not the class
    /// — so it is entered once and every Cloudflare course uses it.
    @Binding var cloudflareAccountID: String

    // MARK: - Computed properties

    /// What is wrong with the chosen folder, or nil when nothing is.
    var folderProblem: String? {
        if deployTarget != "local_folder" {
            return nil
        }
        return CourseConfiguration.deployFolderProblem(forPath: deployFolderPath)
    }

    /// What is wrong with the Cloudflare Account ID, or nil when nothing is.
    var accountProblem: String? {
        if deployTarget != "cloudflare_pages" {
            return nil
        }
        return CourseConfiguration.cloudflareAccountProblem(forID: cloudflareAccountID)
    }

    /// Anything that must be put right before this course can be saved.
    var problem: String? {
        if let folderProblem {
            return folderProblem
        }
        return accountProblem
    }

    // MARK: - Body

    var body: some View {
        Picker("Deploy to", selection: $deployTarget) {
            Text("Netlify").tag("netlify")
            Text("Cloudflare Pages").tag("cloudflare_pages")
            Text("A folder on this Mac").tag("local_folder")
        }
        .accessibilityIdentifier("deployTargetPicker")

        if deployTarget == "cloudflare_pages" {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Cloudflare Account ID", text: $cloudflareAccountID)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("cloudflareAccountField")
                if let accountProblem {
                    // The same orange every other inline warning wears.
                    Text(accountProblem)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("cloudflareAccountProblem")
                } else {
                    ExampleCaption("Each section gets its own free site at yourproject.pages.dev. Sign in at dash.cloudflare.com and open Workers and Pages — the Account ID is shown on the right, and it’s also the long code in the address bar. You only enter it once. The first deploy asks for an API token with the Cloudflare Pages permission.")
                }

                // Not a warning that comes and goes: a fact about this
                // destination that never hides. It is the one real
                // functional difference between the destinations, so a
                // teacher should meet it while choosing rather than when
                // a deploy fails halfway through an upload.
                Text("One thing to know: Cloudflare won’t accept any single file larger than 25 MB. Documents, images, and slide decks are almost always comfortably under that — a long video usually isn’t. Most teachers embed video from YouTube or Vimeo rather than uploading it, which avoids the limit entirely.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("cloudflareSizeNote")
            }
        }

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
                    ExampleCaption("Each section deploys into its own subfolder here — section1, section2 — and only changed files are copied. Upload the folder to your web host however you prefer (e.g. over SFTP). Netlify isn’t involved.")
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
        panel.message = "Choose the folder this course's sections deploy into."
        if panel.runModal() == .OK, let chosen = panel.url {
            deployFolderPath = chosen.path
        }
    }
}
