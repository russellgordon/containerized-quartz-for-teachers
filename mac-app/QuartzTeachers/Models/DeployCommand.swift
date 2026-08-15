import Foundation

/// What `deploy.sh` is asked to do for one section.
///
/// One place decides this, because two now ask: the Deploy button, and the
/// launchd agent a scheduled deploy leaves behind. Building the arguments
/// separately in each would let a scheduled Cloudflare deploy quietly go to
/// Netlify — the failure would appear once, overnight, on a live class site.
enum DeployCommand {

    // MARK: - Stored properties

    /// The launcher in the teacher's working folder.
    static let scriptName: String = "deploy.sh"

    // MARK: - Functions

    /// The arguments for one section's deploy.
    ///
    /// Netlify passes no target flag at all: it is `deploy.sh`'s default,
    /// and every course written before Cloudflare existed relies on that.
    static func arguments(
        courseCode: String,
        sectionNumber: Int,
        configuration: CourseConfiguration,
        cloudflareAccountID: String
    ) -> [String] {
        var arguments: [String] = [courseCode, String(sectionNumber)]
        if configuration.deploysToLocalFolder {
            arguments.append("--to-folder")
            arguments.append(configuration.deployFolderPath)
            return arguments
        }
        if configuration.deploysToCloudflare {
            arguments.append("--target")
            arguments.append("cloudflare")
            // The launcher can discover the account from some tokens and
            // remembers it afterwards, but a token scoped only to Pages
            // cannot list its own account — so the app hands over what the
            // teacher gave it rather than leaving a console prompt that
            // nothing here can answer.
            let identifier: String = cloudflareAccountID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !identifier.isEmpty {
                arguments.append("--account")
                arguments.append(identifier)
            }
        }
        return arguments
    }

    /// Where this course and section deploys, in the teacher's words.
    static func destinationDescription(for configuration: CourseConfiguration) -> String {
        if configuration.deploysToLocalFolder {
            return configuration.deployFolderPath
        }
        if configuration.deploysToCloudflare {
            return "Cloudflare Pages"
        }
        return "Netlify"
    }

    /// The marker file the deployer writes the first time a section goes
    /// out, or nil for a destination that keeps none.
    ///
    /// It is the honest answer to "has this section ever been deployed?" —
    /// `deploy.py` reads it to reuse the site rather than asking what to
    /// call a new one. A folder deploy asks nothing, so it has no marker.
    static func firstDeployMarkerURL(
        forSection sectionNumber: Int,
        in course: Course
    ) -> URL? {
        let configuration: CourseConfiguration = course.configuration
        if configuration.deploysToLocalFolder {
            return nil
        }
        let folderName: String = configuration.deploysToCloudflare ? ".cloudflare_sites" : ".netlify_sites"
        return course.directoryURL
            .appendingPathComponent(folderName)
            .appendingPathComponent("section\(sectionNumber).json")
    }

    /// True when this section has been deployed to its current destination
    /// at least once, so a deploy of it asks the teacher nothing.
    static func hasDeployedBefore(section sectionNumber: Int, in course: Course) -> Bool {
        guard let markerURL = firstDeployMarkerURL(forSection: sectionNumber, in: course) else {
            return true
        }
        return FileManager.default.fileExists(atPath: markerURL.path)
    }
}
