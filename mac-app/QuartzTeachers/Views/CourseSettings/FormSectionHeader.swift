import SwiftUI

/// The standard section heading for forms: a slightly larger title than
/// the default form header, with an optional caption underneath in the
/// same style as `ExampleCaption` hints.
struct FormSectionHeader: View {

    // MARK: - Stored properties

    let title: String
    let caption: String?

    // MARK: - Initializer

    init(_ title: String, caption: String? = nil) {
        self.title = title
        self.caption = caption
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            if let caption {
                Text(caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
        .padding(.bottom, 2)
    }
}
