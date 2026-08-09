import SwiftUI

/// Wraps font sample text in a rounded rectangle with a slightly darker
/// background, so previews read as illustrations rather than settings.
struct FontSampleBox<Content: View>: View {

    // MARK: - Stored properties

    @ViewBuilder var content: Content

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 8))
        .padding(.horizontal, 8)
    }
}
