import SwiftUI

/// Edits the header/body pairing and code font for one section, offering
/// the wizard's curated choices plus free-form custom entry.
struct FontChoiceEditorView: View {

    // MARK: - Stored properties

    @Binding var choice: FontChoice

    // MARK: - Computed properties

    /// The pairing picker works on a "header|body" combined tag so custom
    /// pairings can appear as one extra option.
    var pairingTagBinding: Binding<String> {
        return Binding(
            get: {
                return choice.header + "|" + choice.body
            },
            set: { newTag in
                let parts: [String] = newTag.components(separatedBy: "|")
                if parts.count == 2 {
                    choice.header = parts[0]
                    choice.body = parts[1]
                }
            }
        )
    }

    var pairingOptions: [(tag: String, label: String)] {
        var result: [(tag: String, label: String)] = []
        for pairing in FontCatalog.pairings {
            let tag: String = pairing.header + "|" + pairing.body
            let label: String = FontCatalog.pairingLabel(header: pairing.header, body: pairing.body)
            result.append((tag: tag, label: label))
        }
        let currentTag: String = choice.header + "|" + choice.body
        var isKnown: Bool = false
        for option in result {
            if option.tag == currentTag {
                isKnown = true
            }
        }
        if !isKnown {
            result.append((tag: currentTag, label: "Custom: \(choice.header) — \(choice.body)"))
        }
        return result
    }

    var codeFontOptions: [String] {
        var result: [String] = FontCatalog.codeFonts
        if !result.contains(choice.code) {
            result.append(choice.code)
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        Picker("Header & body fonts", selection: pairingTagBinding) {
            ForEach(pairingOptions, id: \.tag) { option in
                Text(option.label).tag(option.tag)
            }
        }

        Picker("Code font", selection: $choice.code) {
            ForEach(codeFontOptions, id: \.self) { fontName in
                Text(fontName).tag(fontName)
            }
        }
    }
}
