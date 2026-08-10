import CryptoKit
import Foundation

/// The container behind a working folder, and when to let it rest.
///
/// Each working folder has its own container, named after a hash of the
/// folder's path — the launchers derive the same name with
/// `pwd -P | shasum -a 256`, so the trailing newline is part of the hashed
/// input here too. When the last window using a folder closes, that
/// folder's container is stopped: it holds no content (everything lives on
/// the host) and restarts in about a second on the next preview, so keeping
/// it running for nobody would only spend the teacher's memory.
@MainActor
enum FolderContainers {

    // MARK: - Functions

    /// The name the launchers give this folder's container.
    static func containerName(forFolder path: String) -> String {
        // POSIX realpath, because it agrees with `pwd -P` exactly.
        // Foundation's resolvingSymlinksInPath does NOT: it strips the
        // /private prefix from /var and /tmp paths, where pwd -P keeps it,
        // and the two sides would hash different strings.
        var physical: String = path
        if let resolved = realpath(path, nil) {
            physical = String(cString: resolved)
            free(resolved)
        }
        let hashed: SHA256.Digest = SHA256.hash(data: Data((physical + "\n").utf8))
        var hex: String = ""
        for byte in hashed {
            hex += String(format: "%02x", byte)
        }
        return "teaching-quartz-" + String(hex.prefix(8))
    }

    /// Stops the folder's container, quietly, without waiting on it.
    ///
    /// `docker stop`, not `rm`: the container restarts far faster than it
    /// recreates, and the next preview starts it again automatically.
    static func stopContainer(forFolder path: String) {
        if WorkspaceModel.isRunningTests {
            return
        }
        let name: String = containerName(forFolder: path)
        let shell: Process = Process()
        shell.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // A login shell, so docker is on PATH wherever it was installed;
        // backgrounded and disowned, so quitting does not wait on it.
        // A short grace: the container's main process is an idle tail that
        // ignores SIGTERM, and there is nothing in it to save — without -t
        // it would linger the default ten seconds before the kill.
        shell.arguments = ["-l", "-c", "docker stop -t 2 \(name) >/dev/null 2>&1 &!"]
        try? shell.run()
    }
}
