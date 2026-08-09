import SwiftUI

/// A list of checkboxes controlling membership in a string list — used for
/// the "hidden" and "expandable" choices, mirroring the wizard's
/// multi-select prompts.
struct MembershipToggleListView: View {

    // MARK: - Stored properties

    let title: String

    /// Everything that can be toggled.
    let allItems: [String]

    /// The current members (a subset of `allItems`, possibly plus legacy
    /// entries that no longer exist — those are preserved untouched).
    @Binding var members: [String]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            if allItems.isEmpty {
                Text("No folders or files defined yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(allItems, id: \.self) { item in
                Toggle(item, isOn: membershipBinding(for: item))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Functions

    func membershipBinding(for item: String) -> Binding<Bool> {
        return Binding(
            get: {
                return members.contains(item)
            },
            set: { isMember in
                if isMember {
                    if !members.contains(item) {
                        members.append(item)
                    }
                } else {
                    var result: [String] = []
                    for member in members {
                        if member != item {
                            result.append(member)
                        }
                    }
                    members = result
                }
            }
        )
    }
}
