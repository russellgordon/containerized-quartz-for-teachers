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

    /// The on-screen rectangle of the element with this identifier — what a
    /// teacher can actually click, rather than what was drawn.
    @MainActor
    static func frame(forIdentifier identifier: String) -> CGRect? {
        let applicationElement: AXUIElement = AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
        return findFrame(from: applicationElement, identifier: identifier, depth: 0)
    }

    private static func findFrame(from element: AXUIElement, identifier: String, depth: Int) -> CGRect? {
        if depth > 60 {
            return nil
        }

        var identifierValue: CFTypeRef?
        let identifierResult: AXError = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierValue)
        if identifierResult == .success, let found = identifierValue as? String, found == identifier {
            if let rectangle = frameOf(element) {
                return rectangle
            }
        }

        var childrenValue: CFTypeRef?
        let childrenResult: AXError = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        if childrenResult == .success, let children = childrenValue as? [AXUIElement] {
            for child in children {
                if let rectangle = findFrame(from: child, identifier: identifier, depth: depth + 1) {
                    return rectangle
                }
            }
        }
        return nil
    }

    private static func frameOf(_ element: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        let positionResult: AXError = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult: AXError = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        if positionResult != .success || sizeResult != .success {
            return nil
        }
        var origin: CGPoint = .zero
        var size: CGSize = .zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }

    private static func collectLabels(from element: AXUIElement, into labels: inout [String], depth: Int) {
        if depth > 60 {
            return
        }

        let textAttributes: [String] = [
            kAXTitleAttribute as String,
            kAXValueAttribute as String,
            kAXDescriptionAttribute as String,
            // A text field's placeholder (e.g. "Filter") lives here.
            kAXPlaceholderValueAttribute as String,
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
