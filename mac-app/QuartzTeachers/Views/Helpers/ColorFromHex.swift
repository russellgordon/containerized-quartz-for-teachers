import SwiftUI

extension Color {

    // MARK: - Initializer

    /// Creates a colour from a "#rrggbb" or "#rgb" hex string, or from an
    /// "rgba(r, g, b, a)" string — the two formats `colour_schemes.json` uses.
    /// Unparseable strings become grey, matching the terminal picker.
    init(hexString: String) {
        let trimmed: String = hexString.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("#") {
            let digits: String = String(trimmed.dropFirst())
            var redValue: Double = 0.5
            var greenValue: Double = 0.5
            var blueValue: Double = 0.5
            if digits.count == 6 || digits.count == 8 {
                let characters: [Character] = Array(digits)
                let redHex: String = String(characters[0...1])
                let greenHex: String = String(characters[2...3])
                let blueHex: String = String(characters[4...5])
                redValue = Double(Int(redHex, radix: 16) ?? 128) / 255.0
                greenValue = Double(Int(greenHex, radix: 16) ?? 128) / 255.0
                blueValue = Double(Int(blueHex, radix: 16) ?? 128) / 255.0
            } else if digits.count == 3 {
                let characters: [Character] = Array(digits)
                let redHex: String = String(repeating: characters[0], count: 2)
                let greenHex: String = String(repeating: characters[1], count: 2)
                let blueHex: String = String(repeating: characters[2], count: 2)
                redValue = Double(Int(redHex, radix: 16) ?? 128) / 255.0
                greenValue = Double(Int(greenHex, radix: 16) ?? 128) / 255.0
                blueValue = Double(Int(blueHex, radix: 16) ?? 128) / 255.0
            }
            self.init(red: redValue, green: greenValue, blue: blueValue)
            return
        }

        if trimmed.lowercased().hasPrefix("rgba") {
            let openIndex: String.Index? = trimmed.firstIndex(of: "(")
            let closeIndex: String.Index? = trimmed.firstIndex(of: ")")
            if let openIndex, let closeIndex, openIndex < closeIndex {
                let inner: String = String(trimmed[trimmed.index(after: openIndex)..<closeIndex])
                let parts: [String] = inner.components(separatedBy: ",")
                if parts.count >= 3 {
                    let redValue: Double = (Double(parts[0].trimmingCharacters(in: .whitespaces)) ?? 128) / 255.0
                    let greenValue: Double = (Double(parts[1].trimmingCharacters(in: .whitespaces)) ?? 128) / 255.0
                    let blueValue: Double = (Double(parts[2].trimmingCharacters(in: .whitespaces)) ?? 128) / 255.0
                    self.init(red: redValue, green: greenValue, blue: blueValue)
                    return
                }
            }
        }

        self.init(red: 0.5, green: 0.5, blue: 0.5)
    }
}
