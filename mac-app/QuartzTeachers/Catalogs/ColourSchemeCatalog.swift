import Foundation

/// Loads the bundled copy of `colour_schemes.json` (the repository's
/// `support/colour_schemes.json`, included as an app resource).
enum ColourSchemeCatalog {

    // MARK: - Stored properties

    static let schemes: [ColourScheme] = loadSchemes()

    // MARK: - Functions

    static func scheme(withID schemeID: String) -> ColourScheme? {
        for scheme in schemes {
            if scheme.id == schemeID {
                return scheme
            }
        }
        return nil
    }

    private static func loadSchemes() -> [ColourScheme] {
        guard let url = Bundle.main.url(forResource: "colour_schemes", withExtension: "json") else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        guard let decoded = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        // The file is either a bare array or {"schemes": [...]}.
        var rawSchemes: [Any] = []
        if let dictionary = decoded as? [String: Any] {
            if let inner = dictionary["schemes"] as? [Any] {
                rawSchemes = inner
            }
        } else if let array = decoded as? [Any] {
            rawSchemes = array
        }

        var result: [ColourScheme] = []
        for rawScheme in rawSchemes {
            guard let schemeDictionary = rawScheme as? [String: Any] else {
                continue
            }
            guard let schemeID = schemeDictionary["id"] as? String else {
                continue
            }
            var name: String = schemeID
            if let storedName = schemeDictionary["name"] as? String {
                name = storedName
            }
            var lightModeColors: [String: String] = [:]
            var darkModeColors: [String: String] = [:]
            if let colors = schemeDictionary["colors"] as? [String: Any] {
                if let lightMode = colors["lightMode"] as? [String: String] {
                    lightModeColors = lightMode
                }
                if let darkMode = colors["darkMode"] as? [String: String] {
                    darkModeColors = darkMode
                }
            }
            let scheme: ColourScheme = ColourScheme(
                id: schemeID,
                name: name,
                lightModeColors: lightModeColors,
                darkModeColors: darkModeColors
            )
            result.append(scheme)
        }
        return result
    }
}
