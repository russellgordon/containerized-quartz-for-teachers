import SwiftUI

/// The standard style for short "e.g. …" hints under a setting: the same
/// callout size and secondary colour as the "Preview:" label — quiet
/// enough to read as guidance rather than another setting.
struct ExampleCaption: View {

    // MARK: - Stored properties

    let text: String

    // MARK: - Initializer

    init(_ text: String) {
        self.text = text
    }

    // MARK: - Body

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}
