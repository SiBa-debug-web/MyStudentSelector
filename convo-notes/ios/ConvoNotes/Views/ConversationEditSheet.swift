import SwiftUI

struct ConversationEditSheet: View {
    /// nil when logging a brand new conversation.
    let existing: Conversation?
    let defaultKind: ConversationKind
    let knownLocations: [String]
    let onSave: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var kind: ConversationKind
    @State private var date: Date
    @State private var location: String
    @State private var notes: String
    @FocusState private var notesFocused: Bool

    init(existing: Conversation?,
         defaultKind: ConversationKind,
         knownLocations: [String],
         onSave: @escaping (Conversation) -> Void) {
        self.existing = existing
        self.defaultKind = defaultKind
        self.knownLocations = knownLocations
        self.onSave = onSave
        _kind = State(initialValue: existing?.kind ?? defaultKind)
        _date = State(initialValue: existing?.date ?? Date())
        _location = State(initialValue: existing?.location ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        ForEach(ConversationKind.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("When") {
                    DatePicker("Date & time", selection: $date, in: ...Date().addingTimeInterval(60 * 60 * 24 * 365))
                }

                Section {
                    TextField("e.g. Front door, 12 Elm St", text: $location)
                    if !knownLocations.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(knownLocations, id: \.self) { option in
                                    Button(option) { location = option }
                                        .font(.footnote.weight(.semibold))
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(Color.brandSky.opacity(0.14), in: Capsule())
                                        .foregroundStyle(Color.brandSky)
                                        .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Typed by hand — the app never uses your device location.")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 140)
                        .focused($notesFocused)
                }
            }
            .navigationTitle(existing == nil ? "Log conversation" : "Edit conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var conversation = existing ?? Conversation()
                        conversation.kind = kind
                        conversation.date = date
                        conversation.location = location.trimmingCharacters(in: .whitespaces)
                        conversation.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(conversation)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear { notesFocused = existing == nil }
    }
}
