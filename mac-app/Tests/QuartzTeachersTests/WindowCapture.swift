import AppKit
import SwiftUI
import XCTest

/// Captures the app's real window to PNG files from inside the app process.
///
/// The hosted test bundle runs inside the actual app, so the window can be
/// rendered directly — no screen-recording or automation permission needed.
enum WindowCapture {

    // MARK: - Functions

    /// Renders the frontmost window (a sheet, when one is up) into a PNG.
    ///
    /// Note: AppKit vibrancy layers (the sidebar's translucent material)
    /// do not draw in offscreen captures, so the sidebar area appears
    /// blank here; `captureView` below renders SwiftUI content directly
    /// to verify what the sidebar contains.
    @MainActor
    static func captureMainWindow(to outputPath: String) throws {
        var chosenWindow: NSWindow?
        if let keyWindow = NSApp.keyWindow {
            chosenWindow = keyWindow
        } else {
            for candidate in NSApp.windows {
                if candidate.isVisible {
                    chosenWindow = candidate
                    break
                }
            }
        }
        // A sheet attached to a window is frontmost among visible windows.
        for candidate in NSApp.windows {
            if candidate.isVisible && candidate.isSheet {
                chosenWindow = candidate
            }
        }
        guard let window = chosenWindow else {
            throw WindowCaptureError.noVisibleWindow
        }
        guard let contentView = window.contentView else {
            throw WindowCaptureError.noContentView
        }
        let bounds: NSRect = contentView.bounds
        guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw WindowCaptureError.couldNotRender
        }
        contentView.cacheDisplay(in: bounds, to: bitmap)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw WindowCaptureError.couldNotRender
        }
        try pngData.write(to: URL(fileURLWithPath: outputPath))
    }
}

enum WindowCaptureError: Error {
    case noVisibleWindow
    case noContentView
    case couldNotRender
}

extension WindowCapture {

    /// Renders a SwiftUI view directly to a PNG (no window involved) —
    /// used where window captures cannot show vibrancy-backed content.
    @MainActor
    static func captureView(_ view: some View, size: CGSize, to outputPath: String) throws {
        let renderer: ImageRenderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.nsImage else {
            throw WindowCaptureError.couldNotRender
        }
        guard let tiffData = image.tiffRepresentation else {
            throw WindowCaptureError.couldNotRender
        }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw WindowCaptureError.couldNotRender
        }
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw WindowCaptureError.couldNotRender
        }
        try pngData.write(to: URL(fileURLWithPath: outputPath))
    }
}
