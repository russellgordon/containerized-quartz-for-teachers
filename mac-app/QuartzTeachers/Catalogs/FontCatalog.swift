import Foundation

/// The curated font choices the setup wizard offers, mirroring
/// FONT_PAIRINGS and CODE_FONTS in `scripts/setup_course.py`.
enum FontCatalog {

    // MARK: - Stored properties

    /// Header/body pairings (Google Fonts) in wizard order.
    static let pairings: [(header: String, body: String)] = [
        (header: "Playfair Display", body: "Source Sans 3"),
        (header: "Source Serif 4", body: "Inter"),
        (header: "Montserrat", body: "Lora"),
        (header: "Raleway", body: "Roboto"),
        (header: "Poppins", body: "Merriweather"),
        (header: "Archivo", body: "Noto Sans"),
        (header: "Helvetica, Arial", body: "Helvetica, Arial"),
    ]

    /// Monospaced code fonts in wizard order.
    static let codeFonts: [String] = [
        "JetBrains Mono",
        "Fira Code",
        "IBM Plex Mono",
        "Source Code Pro",
        "Inconsolata",
        "Ubuntu Mono",
    ]

    // MARK: - Functions

    /// A display label for a header/body pairing.
    static func pairingLabel(header: String, body: String) -> String {
        if header == "Helvetica, Arial" && body == "Helvetica, Arial" {
            return "System fonts (Helvetica, Arial)"
        }
        return "\(header)  —  \(body)"
    }
}
