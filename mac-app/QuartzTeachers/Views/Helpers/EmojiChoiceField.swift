import AppKit
import SwiftUI

/// One emoji, chosen any way the teacher likes: picked from the wizard's
/// presets, typed straight into the field, or taken from the macOS emoji
/// palette — the smiley button summons it, and whatever is chosen there
/// lands in the field. The field always holds exactly one emoji: the most
/// recently entered one wins, and anything that is not an emoji is ignored.
struct EmojiChoiceField: View {

    // MARK: - Stored properties

    let label: String

    @Binding var emoji: String

    /// The field's live text, which may briefly hold "📚🔬" (the palette
    /// inserts beside what is there) before settling back to one emoji.
    @State var entry: String = ""

    @FocusState var fieldHasFocus: Bool

    // MARK: - Body

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 6) {
                Menu {
                    ForEach(EmojiCatalog.presets, id: \.self) { presetEmoji in
                        Button(presetEmoji) {
                            emoji = presetEmoji
                            entry = presetEmoji
                        }
                    }
                } label: {
                    Text("Presets")
                }
                .fixedSize()

                TextField("", text: $entry)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .focused($fieldHasFocus)
                    .accessibilityIdentifier("emojiChoiceField")
                    .onChange(of: entry) {
                        acceptLatestEmoji()
                    }

                Button {
                    // The palette types into whichever field has focus, so
                    // focus ours before summoning it.
                    fieldHasFocus = true
                    DispatchQueue.main.async {
                        NSApp.orderFrontCharacterPalette(nil)
                    }
                } label: {
                    Image(systemName: "face.smiling")
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Choose any emoji")
                .accessibilityIdentifier("emojiPaletteButton")
            }
        }
        .onAppear {
            entry = emoji
        }
        .onChange(of: emoji) {
            if entry != emoji {
                entry = emoji
            }
        }
    }

    // MARK: - Functions

    /// Settles the field on the most recently entered emoji. An emptied
    /// field is left empty while the teacher decides; anything else that is
    /// not an emoji snaps back to the current choice.
    func acceptLatestEmoji() {
        if entry.isEmpty {
            return
        }
        if let latest = EmojiChoiceField.latestEmoji(in: entry) {
            if entry != latest {
                entry = latest
            }
            if emoji != latest {
                emoji = latest
            }
        } else {
            entry = emoji
        }
    }

    /// The last emoji in the text, or nil when there is none.
    static func latestEmoji(in text: String) -> String? {
        var found: String?
        for character in text {
            if EmojiChoiceField.isEmoji(character) {
                found = String(character)
            }
        }
        return found
    }

    /// Whether one character (one grapheme cluster) reads as an emoji.
    /// Letters and digits report `isEmoji` in Unicode, so a lone scalar
    /// must also insist on emoji *presentation*; multi-scalar clusters
    /// (skin tones, ZWJ sequences like 🧑‍🚀, flags, keycaps) are trusted by
    /// their first scalar.
    static func isEmoji(_ character: Character) -> Bool {
        let scalars: [Unicode.Scalar] = Array(character.unicodeScalars)
        guard let firstScalar = scalars.first else {
            return false
        }
        if scalars.count > 1 {
            return firstScalar.properties.isEmoji
        }
        return firstScalar.properties.isEmojiPresentation && firstScalar.value > 0x238C
    }
}
