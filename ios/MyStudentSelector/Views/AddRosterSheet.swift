import SwiftUI

struct AddRosterSheet: View {
    enum Mode {
        case create
        case rename(current: String)

        var title: String {
            switch self {
            case .create: return "New class"
            case .rename: return "Rename class"
            }
        }

        var initialValue: String {
            switch self {
            case .create: return ""
            case .rename(let current): return current
            }
        }

        var saveLabel: String {
            switch self {
            case .create: return "Create"
            case .rename: return "Save"
            }
        }
    }

    let mode: Mode
    let onSave: (String) -> UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    init(mode: Mode, onSave: @escaping (String) -> UUID?) {
        self.mode = mode
        self.onSave = onSave
        _name = State(initialValue: mode.initialValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Period 3 — Chemistry", text: $name)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.saveLabel, action: save)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { isFocused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        _ = onSave(trimmed)
        dismiss()
    }
}

#Preview {
    AddRosterSheet(mode: .create) { _ in nil }
}
