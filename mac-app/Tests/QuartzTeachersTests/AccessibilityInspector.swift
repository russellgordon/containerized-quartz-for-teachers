import AppKit
import ApplicationServices

/// Walks the app's own accessibility tree (the one VoiceOver and XCUITest
/// read) and collects every piece of text it exposes. Because the tree
/// belongs to this same process, no automation permission is needed.
enum AccessibilityInspector {

    // MARK: - Functions

    /// Every title/value/description string in the app's current UI.
    @MainActor
    static func collectAllLabels() -> [String] {
        let applicationElement: AXUIElement = AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
        var labels: [String] = []
        collectLabels(from: applicationElement, into: &labels, depth: 0)
        return labels
    }

    private static func collectLabels(from element: AXUIElement, into labels: inout [String], depth: Int) {
        if depth > 60 {
            return
        }

        let textAttributes: [String] = [
            kAXTitleAttribute as String,
            kAXValueAttribute as String,
            kAXDescriptionAttribute as String,
        ]
        for attributeName in textAttributes {
            var attributeValue: CFTypeRef?
            let result: AXError = AXUIElementCopyAttributeValue(element, attributeName as CFString, &attributeValue)
            if result == .success {
                if let text = attributeValue as? String {
                    if !text.isEmpty {
                        labels.append(text)
                    }
                }
            }
        }

        var childrenValue: CFTypeRef?
        let childrenResult: AXError = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        if childrenResult != .success {
            return
        }
        guard let children = childrenValue as? [AXUIElement] else {
            return
        }
        for child in children {
            collectLabels(from: child, into: &labels, depth: depth + 1)
        }
    }
}
