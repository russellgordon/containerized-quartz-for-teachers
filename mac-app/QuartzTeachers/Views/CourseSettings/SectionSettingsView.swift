import SwiftUI

/// The per-section settings for one section of a course: header emoji,
/// colour scheme, fonts, and the "S1" marker toggle.
struct SectionSettingsView: View {

    // MARK: - Stored properties

    @Bindable var configuration: CourseConfiguration

    let sectionNumber: Int

    // MARK: - Computed properties

    var emojiBinding: Binding<String> {
        return Binding(
            get: { configuration.emoji(forSection: sectionNumber) },
            set: { newEmoji in configuration.setEmoji(newEmoji, forSection: sectionNumber) }
        )
    }

    var markerBinding: Binding<Bool> {
        return Binding(
            get: { configuration.showsSectionMarker(forSection: sectionNumber) },
            set: { newValue in configuration.setShowsSectionMarker(newValue, forSection: sectionNumber) }
        )
    }

    var schemeBinding: Binding<String> {
        return Binding(
            get: { configuration.colourSchemeID(forSection: sectionNumber) },
            set: { newSchemeID in configuration.setColourSchemeID(newSchemeID, forSection: sectionNumber) }
        )
    }

    var fontBinding: Binding<FontChoice> {
        return Binding(
            get: { configuration.fontChoice(forSection: sectionNumber) },
            set: { newChoice in configuration.setFontChoice(newChoice, forSection: sectionNumber) }
        )
    }

    // MARK: - Body

    var body: some View {
        Section("Section \(sectionNumber) Settings") {
            Picker("Header emoji", selection: emojiBinding) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Text(emoji).tag(emoji)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show section marker in the site title", isOn: markerBinding)
                ExampleCaption("e.g. “S\(sectionNumber)” appears beside the course code")
            }

            ColourSchemePickerView(selectedSchemeID: schemeBinding)

            FontChoiceEditorView(choice: fontBinding)
        }
    }

    /// The preset emojis, plus the currently stored one when it is custom.
    var emojiOptions: [String] {
        var result: [String] = EmojiCatalog.presets
        let current: String = configuration.emoji(forSection: sectionNumber)
        if !result.contains(current) {
            result.append(current)
        }
        return result
    }
}
