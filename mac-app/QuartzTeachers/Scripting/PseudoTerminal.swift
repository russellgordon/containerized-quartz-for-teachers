import Darwin
import Foundation

/// A pseudo-terminal (PTY) pair.
///
/// The toolchain's scripts run `docker exec -it`, which insists on having a
/// real terminal on standard input. Running the scripts with plain pipes
/// would make that step fail, so the app attaches each script to the slave
/// side of a PTY and reads/writes the master side instead — exactly what
/// Terminal.app does for a shell.
struct PseudoTerminal {

    // MARK: - Stored properties

    /// The app's side: read script output here, write keystrokes here.
    let masterHandle: FileHandle

    /// The script's side: becomes the child process's stdin/stdout/stderr.
    let slaveHandle: FileHandle

    // MARK: - Initializer

    init() throws {
        var masterDescriptor: Int32 = -1
        var slaveDescriptor: Int32 = -1
        let result: Int32 = openpty(&masterDescriptor, &slaveDescriptor, nil, nil, nil)
        if result != 0 {
            throw PseudoTerminalError.couldNotOpen
        }
        self.masterHandle = FileHandle(fileDescriptor: masterDescriptor, closeOnDealloc: true)
        self.slaveHandle = FileHandle(fileDescriptor: slaveDescriptor, closeOnDealloc: true)
    }
}

enum PseudoTerminalError: Error {
    case couldNotOpen
}
