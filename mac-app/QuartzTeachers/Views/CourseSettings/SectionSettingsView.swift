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

    var customDomainBinding: Binding<String> {
        return Binding(
            get: { configuration.customDomain(forSection: sectionNumber) },
            set: { newDomain in
                configuration.setCustomDomain(
                    CourseConfiguration.normalizedCustomDomain(newDomain),
                    forSection: sectionNumber
                )
            }
        )
    }

    /// A gentle warning when the entry does not read as a domain.
    var customDomainProblem: String? {
        let domain: String = configuration.customDomain(forSection: sectionNumber)
        if domain.isEmpty {
            return nil
        }
        if domain.contains(" ") || !domain.contains(".") {
            return "That doesn’t look like a domain — e.g. ics3u.yourschool.ca"
        }
        return nil
    }

    var fontBinding: Binding<FontChoice> {
        return Binding(
            get: { configuration.fontChoice(forSection: sectionNumber) },
            set: { newChoice in configuration.setFontChoice(newChoice, forSection: sectionNumber) }
        )
    }

    // MARK: - Body

    var body: some View {
        Section {
            EmojiChoiceField(label: "Header emoji", emoji: emojiBinding)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Show section marker in the site title", isOn: markerBinding)
                ExampleCaption("e.g. “S\(sectionNumber)” appears beside the course code")
            }

            ColourSchemePickerView(selectedSchemeID: schemeBinding)

            FontChoiceEditorView(choice: fontBinding)

            DisclosureGroup("Advanced") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Custom domain", text: customDomainBinding)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("customDomainField-section\(sectionNumber)")
                    if let customDomainProblem {
                        Text(customDomainProblem)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        ExampleCaption("e.g. ics3u.yourschool.ca — links to your published site will use this domain instead of the Netlify address. Your site must already answer there (set the domain up in Netlify first). Leave empty to use the Netlify address.")
                    }
                }
                .padding(.top, 4)
            }
        } header: {
            FormSectionHeader("Section \(sectionNumber) Settings")
        }
    }

}
