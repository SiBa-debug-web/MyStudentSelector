import SwiftUI

struct AddStudentsSheet: View {
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var singleName: String = ""
    @State private var bulkNames: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Add one name…", text: $singleName)
                        .focused($isFocused)
                }
                Section {
                    TextEditor(text: $bulkNames)
                        .frame(minHeight: 120)
                } header: {
                    Text("Or paste a list")
                } footer: {
                    Text("One name per line, or separated by commas.")
                }
            }
            .navigationTitle("Add students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(singleName, bulkNames)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(singleName.trimmingCharacters(in: .whitespaces).isEmpty && bulkNames.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

#Preview {
    AddStudentsSheet { _, _ in }
}
