import SwiftUI

/// Edits a list of names (folders or files): shows the current entries with
/// remove buttons, and a field for adding a new entry.
struct StringListEditorView: View {

    // MARK: - Stored properties

    let title: String

    @Binding var items: [String]

    @State var newItemName: String = ""

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            if items.isEmpty {
                Text("None")
                    .foregroundStyle(.secondary)
            }

            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Button("Remove \(item)", systemImage: "minus.circle") {
                        removeItem(named: item)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                TextField("Add…", text: $newItemName)
                    .onSubmit {
                        addNewItem()
                    }
                Button("Add", systemImage: "plus.circle") {
                    addNewItem()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Functions

    func addNewItem() {
        let trimmed: String = newItemName.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return
        }
        if trimmed == "Media" {
            // The toolchain manages the Media folder automatically; the
            // wizard refuses this name too.
            newItemName = ""
            return
        }
        if !items.contains(trimmed) {
            items.append(trimmed)
        }
        newItemName = ""
    }

    func removeItem(named name: String) {
        var result: [String] = []
        for item in items {
            if item != name {
                result.append(item)
            }
        }
        items = result
    }
}
