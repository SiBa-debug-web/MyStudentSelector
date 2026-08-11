import SwiftUI

struct PersonEditSheet: View {
    /// nil when adding someone new.
    let person: Person?
    let onSave: (String, PersonCategory, String) -> Void

    @EnvironmentObject private var store: PersonStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: PersonCategory
    @State private var suburb: String
    @FocusState private var nameFocused: Bool

    init(person: Person?, onSave: @escaping (String, PersonCategory, String) -> Void) {
        self.person = person
        self.onSave = onSave
        _name = State(initialValue: person?.name ?? "")
        _category = State(initialValue: person?.category ?? .man)
        _suburb = State(initialValue: person?.suburb ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Sarah Nguyen", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                }

                Section("Who is this?") {
                    Picker("Category", selection: $category) {
                        ForEach(PersonCategory.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("e.g. Northcote", text: $suburb)
                    if !store.suburbs.isEmpty {
                        // Tap to reuse a suburb already in the list, so the
                        // filter doesn't fill up with near-duplicate spellings.
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(store.suburbs, id: \.self) { option in
                                    Button(option) { suburb = option }
                                        .font(.footnote.weight(.semibold))
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(Color.brandTeal.opacity(0.14), in: Capsule())
                                        .foregroundStyle(Color.brandTeal)
                                        .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Suburb")
                } footer: {
                    Text("Used to filter your list of people.")
                }
            }
            .navigationTitle(person == nil ? "Add person" : "Edit person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmedName, category, suburb.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .onAppear { nameFocused = person == nil }
    }
}
