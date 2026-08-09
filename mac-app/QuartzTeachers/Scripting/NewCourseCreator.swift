import Foundation
import Observation

/// Creates a new course by driving the real setup wizard.
///
/// The app writes the teacher's chosen settings to
/// `courses/<CODE>/course_config.json` first, then runs `./setup.sh`. The
/// wizard treats that file as its saved answers and offers each one as a
/// default, so this type simply watches the output and "presses Return" at
/// every prompt (typing the course code at the one prompt that needs it).
/// All folder scaffolding, backups, and Quartz patching happen inside the
/// real script — the app adds no logic of its own.
@Observable
class NewCourseCreator {

    // MARK: - Stored properties

    let runner: ScriptRunner = ScriptRunner()

    /// True from start until setup.sh finishes.
    var isCreating: Bool = false

    /// A problem preparing the run (before the script started), if any.
    var preparationProblem: String?

    /// The course code being created, uppercased.
    private var courseCode: String = ""

    /// How much of the transcript the pump has already responded to.
    private var respondedLength: Int = 0

    /// Safety valve so a confused run cannot send input forever.
    private var responsesSent: Int = 0

    // MARK: - Functions

    /// Writes the config, then starts `setup.sh` and the answer pump.
    func createCourse(configuration: [String: Any], workspaceURL: URL) {
        preparationProblem = nil

        guard let storedCode = configuration["course_code"] as? String else {
            preparationProblem = "The course needs a code."
            return
        }
        courseCode = storedCode.uppercased()

        let courseDirectoryURL: URL = workspaceURL
            .appendingPathComponent("courses")
            .appendingPathComponent(courseCode)
        let configFileURL: URL = courseDirectoryURL.appendingPathComponent("course_config.json")

        do {
            try FileManager.default.createDirectory(at: courseDirectoryURL, withIntermediateDirectories: true)
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var data: Data = try JSONSerialization.data(withJSONObject: configuration, options: options)
            data.append(contentsOf: [0x0A])
            try data.write(to: configFileURL, options: [.atomic])
        } catch {
            preparationProblem = "Could not write the course configuration: \(error.localizedDescription)"
            return
        }

        respondedLength = 0
        responsesSent = 0
        isCreating = true
        runner.run(scriptNamed: "setup.sh", arguments: [], workingDirectory: workspaceURL)

        Task {
            await pumpAnswers()
        }
    }

    /// Watches the wizard's output; whenever a prompt is waiting, answers
    /// it — the course code at the code prompt, Return everywhere else.
    private func pumpAnswers() async {
        while runner.isRunning {
            try? await Task.sleep(for: .milliseconds(400))

            if responsesSent > 300 {
                // Something is looping; stop feeding it.
                runner.terminate()
                break
            }

            let displayText: String = runner.transcript.displayText
            if displayText.count == respondedLength {
                // No new output since our last response; the script is
                // either busy working or waiting at a prompt we already
                // answered. Only answer when NEW output ends in a prompt.
                continue
            }

            let lastLine: String = currentPromptLine(in: displayText)
            if !looksLikePrompt(lastLine) {
                continue
            }

            respondedLength = displayText.count
            responsesSent += 1

            if lastLine.contains("Enter the course code") {
                runner.send(line: courseCode)
            } else {
                runner.send(line: "")
            }
        }
        isCreating = false
    }

    /// The last non-empty line of output — the prompt currently waiting.
    private func currentPromptLine(in text: String) -> String {
        let lines: [Substring] = text.split(separator: "\n", omittingEmptySubsequences: false)
        var index: Int = lines.count - 1
        while index >= 0 {
            let line: String = String(lines[index]).trimmingCharacters(in: .whitespaces)
            if !line.isEmpty {
                return line
            }
            index -= 1
        }
        return ""
    }

    /// Heuristics for "the wizard is waiting for input on this line" —
    /// matched to the actual prompt shapes in setup_course.py.
    private func looksLikePrompt(_ line: String) -> Bool {
        if line.hasSuffix(":") {
            return true
        }
        if line.hasSuffix(": ") {
            return true
        }
        if line == ">" {
            return true
        }
        if line.hasPrefix("Use ← / →") {
            // The colour scheme picker: Return accepts the saved default.
            return true
        }
        if line.hasSuffix("?") {
            return true
        }
        return false
    }
}
