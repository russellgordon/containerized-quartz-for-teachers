import Foundation

/// One step of a long-running task: the text shown to the teacher, and
/// the marker in the output that means the step has been reached.
struct TaskMilestone {

    // MARK: - Stored properties

    /// Brief, meaningful label, e.g. "Building your site".
    let label: String

    /// A phrase that appears in the output when this step begins.
    let marker: String
}

/// The ordered milestones for each kind of task. Progress is "how many
/// milestones have been reached", so the bar advances in real steps
/// rather than spinning indefinitely.
enum TaskMilestones {

    // MARK: - Stored properties

    /// Creating a course: the wizard's own progression.
    static let courseCreation: [TaskMilestone] = [
        TaskMilestone(label: "Getting ready", marker: "Welcome to the Course Setup Script"),
        TaskMilestone(label: "Preparing your course folder", marker: "'Media' folder"),
        TaskMilestone(label: "Choosing appearance", marker: "Quartz Locale"),
        TaskMilestone(label: "Setting up sections", marker: "timetable section numbers"),
        TaskMilestone(label: "Creating folders and files", marker: "Select folders/files to HIDE"),
        TaskMilestone(label: "Finishing up", marker: "set up successfully"),
    ]

    /// Previewing a section.
    static let preview: [TaskMilestone] = [
        TaskMilestone(label: "Starting up", marker: "Starting container if needed"),
        TaskMilestone(label: "Gathering your content", marker: "Copying shared folders"),
        TaskMilestone(label: "Applying your settings", marker: "Updated pageTitle"),
        TaskMilestone(label: "Preparing components", marker: "Installing dependencies"),
        TaskMilestone(label: "Building your site", marker: "Quartz v4"),
        TaskMilestone(label: "Opening the preview", marker: "Launching Quartz preview"),
    ]

    /// Publishing a section to Netlify.
    static let deploy: [TaskMilestone] = [
        TaskMilestone(label: "Starting up", marker: "Ensuring container is running"),
        TaskMilestone(label: "Checking your site", marker: "Deploying from local build"),
        TaskMilestone(label: "Connecting to Netlify", marker: "Netlify site"),
        TaskMilestone(label: "Comparing what changed", marker: "delta deploy manifest"),
        TaskMilestone(label: "Uploading your pages", marker: "Uploaded"),
        TaskMilestone(label: "Finishing up", marker: "Deploy complete"),
    ]

    // MARK: - Functions

    /// How many milestones the output shows as reached (0…count).
    static func reachedCount(in outputText: String, milestones: [TaskMilestone]) -> Int {
        var reached: Int = 0
        for index in 0..<milestones.count {
            if outputText.contains(milestones[index].marker) {
                // A later marker implies the earlier steps are done, even
                // if a marker was missed (output varies between runs).
                reached = index + 1
            }
        }
        return reached
    }
}
