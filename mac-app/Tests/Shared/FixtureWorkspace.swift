import Foundation

/// Builds a disposable working folder for tests: the real launcher scripts
/// plus the Example Course's configuration, laid out the way a teacher's
/// folder is. Each call returns a fresh temporary copy, so tests can
/// mutate it freely and runs never interfere with each other.
///
/// The pieces are bundled into the test targets as resources, which means
/// plain Cmd-U in Xcode needs no environment variables at all.
enum FixtureWorkspace {

    // MARK: - Functions

    static func materialize() throws -> URL {
        let bundle: Bundle = Bundle(for: BundleToken.self)
        let fileManager: FileManager = FileManager.default

        let rootURL: URL = fileManager.temporaryDirectory
            .appendingPathComponent("cq4t-fixture-\(UUID().uuidString)")
        let courseURL: URL = rootURL
            .appendingPathComponent("courses")
            .appendingPathComponent("EXC2O")
        try fileManager.createDirectory(
            at: courseURL.appendingPathComponent("section1"),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: courseURL.appendingPathComponent("section2"),
            withIntermediateDirectories: true
        )

        let scriptNames: [String] = ["setup.sh", "preview.sh", "deploy.sh"]
        for scriptName in scriptNames {
            guard let sourceURL = bundle.url(forResource: scriptName, withExtension: nil) else {
                throw FixtureWorkspaceError.missingResource(scriptName)
            }
            let destinationURL: URL = rootURL.appendingPathComponent(scriptName)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            try fileManager.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: destinationURL.path
            )
        }

        guard let configURL = bundle.url(forResource: "course_config", withExtension: "json") else {
            throw FixtureWorkspaceError.missingResource("course_config.json")
        }
        try fileManager.copyItem(
            at: configURL,
            to: courseURL.appendingPathComponent("course_config.json")
        )

        return rootURL
    }
}

enum FixtureWorkspaceError: Error {
    case missingResource(String)
}

/// Exists only so `Bundle(for:)` can locate the test bundle.
private final class BundleToken {}
