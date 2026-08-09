import Foundation

/// Turns raw terminal output into clean display lines.
///
/// The scripts produce terminal control sequences (colours, spinners that
/// redraw the same line with carriage returns, cursor movement). Teachers
/// should see tidy text, so this type strips ANSI escape sequences and
/// treats a carriage return as "start this line over", which collapses
/// spinner animation into its final state.
struct TranscriptBuilder {

    // MARK: - Stored properties

    /// Completed lines of output, oldest first.
    var lines: [String] = []

    /// The line currently being assembled (not yet ended with a newline).
    var currentLine: String = ""

    /// True when the previous chunk ended with a carriage return whose
    /// meaning (line ending vs. spinner redraw) depends on what follows.
    var hasPendingCarriageReturn: Bool = false

    // MARK: - Computed properties

    /// The full transcript as one display string.
    var displayText: String {
        var allLines: [String] = lines
        if !currentLine.isEmpty {
            allLines.append(currentLine)
        }
        return allLines.joined(separator: "\n")
    }

    // MARK: - Functions

    /// Feed a chunk of raw output from the PTY into the transcript.
    ///
    /// A pseudo-terminal turns every "\n" the script prints into "\r\n",
    /// so a carriage return followed by a newline is an ordinary line
    /// ending. Only a LONE carriage return is a spinner redrawing its
    /// line, which is when the current line restarts.
    mutating func append(rawText: String) {
        let cleaned: String = TranscriptBuilder.strippingControlSequences(from: rawText)
        // Work scalar-by-scalar: Swift groups "\r\n" into a SINGLE
        // Character (grapheme cluster), which would hide line endings.
        let newlineScalar: Unicode.Scalar = "\n"
        let carriageReturnScalar: Unicode.Scalar = "\r"
        for scalar in cleaned.unicodeScalars {
            if hasPendingCarriageReturn {
                hasPendingCarriageReturn = false
                if scalar == newlineScalar {
                    // "\r\n": a normal line ending.
                    lines.append(currentLine)
                    currentLine = ""
                    continue
                }
                // A lone "\r": spinner redraw — restart the line, then
                // process the current scalar normally below.
                currentLine = ""
            }
            if scalar == newlineScalar {
                lines.append(currentLine)
                currentLine = ""
            } else if scalar == carriageReturnScalar {
                hasPendingCarriageReturn = true
            } else {
                currentLine.unicodeScalars.append(scalar)
            }
        }
    }

    /// Removes ANSI escape sequences and stray control characters,
    /// keeping newlines, carriage returns, and tabs.
    ///
    /// Operates on Unicode scalars, not Characters, because Swift folds
    /// "\r\n" into one Character and would misclassify it as a control
    /// character to remove.
    static func strippingControlSequences(from text: String) -> String {
        var result: String = ""
        let scalars: [Unicode.Scalar] = Array(text.unicodeScalars)
        let escapeScalar: Unicode.Scalar = "\u{1B}"
        let bellScalar: Unicode.Scalar = "\u{07}"
        var index: Int = 0
        while index < scalars.count {
            let scalar: Unicode.Scalar = scalars[index]
            if scalar == escapeScalar {
                // Escape sequence: skip "ESC [ ... final-letter" (CSI) or
                // "ESC ] ... BEL" (OSC), or a single following scalar.
                let nextIndex: Int = index + 1
                if nextIndex < scalars.count && scalars[nextIndex] == "[" {
                    var scanIndex: Int = nextIndex + 1
                    while scanIndex < scalars.count {
                        let scanned: Unicode.Scalar = scalars[scanIndex]
                        let isFinalLetter: Bool = (scanned >= "A" && scanned <= "Z") || (scanned >= "a" && scanned <= "z")
                        if isFinalLetter {
                            break
                        }
                        scanIndex += 1
                    }
                    index = scanIndex + 1
                    continue
                }
                if nextIndex < scalars.count && scalars[nextIndex] == "]" {
                    var scanIndex: Int = nextIndex + 1
                    while scanIndex < scalars.count {
                        let scanned: Unicode.Scalar = scalars[scanIndex]
                        if scanned == bellScalar {
                            break
                        }
                        scanIndex += 1
                    }
                    index = scanIndex + 1
                    continue
                }
                index = index + 2
                continue
            }
            let isControl: Bool = scalar.value < 32
            let isKeeper: Bool = scalar == "\n" || scalar == "\r" || scalar == "\t"
            if isControl && !isKeeper {
                index += 1
                continue
            }
            result.unicodeScalars.append(scalar)
            index += 1
        }
        return result
    }
}
