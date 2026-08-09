import AppKit
import XCTest
@testable import QuartzTeachers

/// Every font family the wizard offers must be available for previews
/// after the app registers its bundled fonts at launch.
final class BundledFontTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testEveryCatalogFamilyIsAvailableAfterRegistration() {
        // The hosted app has already run its initializer, but registering
        // again must also be harmless.
        BundledFontList.registerFonts()

        var familiesToCheck: [String] = []
        for pairing in FontCatalog.pairings {
            if pairing.header != "Helvetica, Arial" {
                familiesToCheck.append(pairing.header)
                familiesToCheck.append(pairing.body)
            }
        }
        for codeFont in FontCatalog.codeFonts {
            familiesToCheck.append(codeFont)
        }

        for familyName in familiesToCheck {
            let descriptor: NSFontDescriptor = NSFontDescriptor(fontAttributes: [.family: familyName])
            let matched: NSFontDescriptor? = descriptor.matchingFontDescriptor(withMandatoryKeys: [.family])
            XCTAssertNotNil(matched, "Font family should be registered and available: \(familyName)")
        }
    }
}
