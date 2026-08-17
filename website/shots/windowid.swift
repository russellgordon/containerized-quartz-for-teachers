// Prints the window number of an application's largest ordinary window.
//
// `screencapture -l <window-number>` grabs THAT WINDOW's own contents,
// whatever is in front of it and wherever it sits — which a region capture
// cannot do. A region capture photographs a rectangle of the screen, so a
// window that had not finished coming to the front produced a screenshot of
// whatever was behind it. That happened, and the result was a picture of a
// terminal filed as a class website.
//
// Usage: swift windowid.swift "Safari"

import CoreGraphics
import Foundation

let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Safari"

guard let windows = CGWindowListCopyWindowInfo(
    [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
) as? [[String: Any]] else {
    FileHandle.standardError.write("Could not list windows.\n".data(using: .utf8)!)
    exit(1)
}

var bestNumber: Int = 0
var bestArea: Double = 0

for window in windows {
    guard let name = window[kCGWindowOwnerName as String] as? String, name == owner else {
        continue
    }
    // Layer 0 is an ordinary document window; panels and overlays sit above.
    let layer = window[kCGWindowLayer as String] as? Int ?? 0
    guard layer == 0 else {
        continue
    }
    guard let number = window[kCGWindowNumber as String] as? Int,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? Double,
          let height = bounds["Height"] as? Double else {
        continue
    }
    let area = width * height
    if area > bestArea {
        bestArea = area
        bestNumber = number
    }
}

if bestNumber == 0 {
    FileHandle.standardError.write("No ordinary window found for \(owner).\n".data(using: .utf8)!)
    exit(2)
}

print(bestNumber)
