import CoreText
import Foundation

/// The font files bundled with the app so the settings form can preview
/// the site font choices. Each case's raw value is the resource file name
/// (all `.ttf`); the families match the names in `FontCatalog`.
///
/// Pattern adapted from the Canopy app's `CustomFontList`.
enum BundledFontList: String, CaseIterable {

    // MARK: - Cases

    case archivo = "Archivo"
    case firaCode = "FiraCode"
    case ibmPlexMono = "IBMPlexMono"
    case inconsolata = "Inconsolata"
    case inter = "Inter"
    case jetBrainsMono = "JetBrainsMono"
    case lora = "Lora"
    case merriweather = "Merriweather"
    case montserrat = "Montserrat"
    case notoSans = "NotoSans"
    case playfairDisplay = "PlayfairDisplay"
    case poppins = "Poppins"
    case raleway = "Raleway"
    case roboto = "Roboto"
    case sourceCodePro = "SourceCodePro"
    case sourceSans3 = "SourceSans3"
    case sourceSerif4 = "SourceSerif4"
    case ubuntuMono = "UbuntuMono"

    // MARK: - Functions

    /// Registers every bundled font with the system for this process.
    /// Called once at app start; safe to call again (re-registration
    /// errors are ignored).
    static func registerFonts() {
        for currentFont in BundledFontList.allCases {
            registerFont(fontName: currentFont.rawValue, fontExtension: "ttf")
        }
    }

    /// Finds one font file in the bundle and registers it for this
    /// process (the modern replacement for the older
    /// CGFont/CTFontManagerRegisterGraphicsFont approach, which macOS 15
    /// deprecates).
    ///
    /// Unlike the original pattern this does not crash on failure — a
    /// missing font only means a preview falls back to the system font,
    /// which is never worth stopping a teacher's work over.
    private static func registerFont(fontName: String, fontExtension: String) {
        guard let fontURL = Bundle.main.url(forResource: fontName, withExtension: fontExtension) else {
            print("⚠️ Bundled font not found: \(fontName).\(fontExtension)")
            return
        }
        var registrationError: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError)
    }
}
