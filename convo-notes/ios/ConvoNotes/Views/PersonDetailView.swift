import SwiftUI

struct PersonDetailView: View {
    let personID: UUID

    @EnvironmentObject private var store: PersonStore
    @Environment(\.dismiss) private var dismiss

    @State private var showEditPerson = false
    @State private var showDeleteConfirm = false
    @State private var conversationTarget: ConversationTarget?

    private struct ConversationTarget: Identifiable {
        let id = UUID()
        let existing: Conversation?
    }

    private var person: Person? { store.person(id: personID) }

    var body: some View {
        Group {
            if let person {
                content(for: person)
            } else {
                // The person was deleted while this view was on screen.
                Color.clear
            }
        }
    }

    @ViewBuilder
    private func content(for person: Person) -> some View {
        List {
            Section {
                headerCard(for: person)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                if person.conversations.isEmpty {
                    emptyConversations
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(person.sortedConversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                conversationTarget = ConversationTarget(existing: conversation)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteConversation(personID: person.id,
                                                             conversationID: conversation.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Conversations")
                    if !person.conversations.isEmpty {
                        Text("(\(person.conversations.count))").foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button("Log conversation") {
                        conversationTarget = ConversationTarget(existing: nil)
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandTeal)
                    .textCase(nil)
                }
                .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditPerson = true
                    } label: {
                        Label("Edit details", systemImage: "pencil")
                    }
                    Button {
                        store.toggleShortlist(id: person.id)
                    } label: {
                        Label(person.isShortlisted ? "Remove from shortlist" : "Add to shortlist",
                              systemImage: person.isShortlisted ? "star.slash" : "star")
                    }
                    Button {
                        store.toggleArchive(id: person.id)
                    } label: {
                        Label(person.isArchived ? "Unarchive (resume)" : "Archive (pause)",
                              systemImage: person.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete person", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    conversationTarget = ConversationTarget(existing: nil)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Log conversation")
            }
        }
        .sheet(isPresented: $showEditPerson) {
            PersonEditSheet(person: person) { name, category, suburb in
                store.updatePerson(id: person.id, name: name, category: category, suburb: suburb)
            }
        }
        .sheet(item: $conversationTarget) { target in
            ConversationEditSheet(
                existing: target.existing,
                defaultKind: store.defaultKind(for: person.id),
                knownLocations: store.knownLocations
            ) { conversation in
                if target.existing == nil {
                    store.addConversation(to: person.id, conversation: conversation)
                } else {
                    store.updateConversation(personID: person.id, conversation: conversation)
                }
            }
        }
        .alert("Delete \(person.name)?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deletePerson(id: person.id)
                dismiss()
            }
        } message: {
            Text("This removes them and all their conversations. It can't be undone.")
        }
    }

    // MARK: - Header

    private func headerCard(for person: Person) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 13) {
                AvatarView(person: person, size: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(person.name).font(.title3.bold())
                    Text(person.suburb.isEmpty
                         ? person.category.label
                         : "\(person.category.label) · \(person.suburb)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    store.toggleShortlist(id: person.id)
                } label: {
                    Image(systemName: person.isShortlisted ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(person.isShortlisted ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(person.isShortlisted ? "Remove from shortlist" : "Add to shortlist")
            }

            if person.isArchived {
                banner(
                    icon: "archivebox.fill",
                    text: "Archived — this conversation is paused. Reminders are off.",
                    color: .secondary
                )
            } else if person.isOverdue {
                banner(
                    icon: "clock.badge.exclamationmark",
                    text: "No follow-up in \(person.daysSinceActivity) days — time to check in.",
                    color: .orange
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func banner(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text).fontWeight(.semibold)
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .foregroundStyle(color)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var emptyConversations: some View {
        VStack(spacing: 9) {
            Text("🗒️").font(.system(size: 34))
            Text("No conversations logged").font(.headline)
            Text("Record your first conversation with this person.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Log conversation") {
                conversationTarget = ConversationTarget(existing: nil)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandTeal)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(conversation.kind.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.4)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(kindColor.opacity(0.18), in: Capsule())
                    .foregroundStyle(kindColor)

                Text(conversation.formattedDate)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            if !conversation.location.isEmpty {
                Label(conversation.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !conversation.notes.isEmpty {
                Text(conversation.notes)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
    }

    private var kindColor: Color {
        conversation.kind == .initial ? .brandTeal : .brandSky
    }
}
