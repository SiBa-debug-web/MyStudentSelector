import SwiftUI
import UIKit

struct RosterDetailView: View {
    let rosterId: UUID
    @EnvironmentObject private var store: RosterStore
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var hasPicked = false
    @State private var isPicking = false
    @State private var lastPickedTimesCalled = 0

    @State private var showAddStudents = false
    @State private var showRename = false
    @State private var showDeleteConfirm = false
    @State private var showResetStatsConfirm = false

    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastTask: Task<Void, Never>?

    private var roster: Roster? { store.roster(id: rosterId) }

    var body: some View {
        Group {
            if let roster {
                detail(for: roster)
            }
        }
    }

    @ViewBuilder
    private func detail(for roster: Roster) -> some View {
        List {
            Section {
                pickerCard(for: roster)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                if roster.students.isEmpty {
                    studentsEmptyState
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(sortedStudents(roster)) { student in
                        StudentRowView(student: student)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteStudent(rosterId: roster.id, studentId: student.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    store.toggleAbsent(rosterId: roster.id, studentId: student.id)
                                } label: {
                                    Label(student.isAbsent ? "Present" : "Absent", systemImage: "person.fill.questionmark")
                                }
                                .tint(.orange)
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Roster")
                    Spacer()
                    Button("Add students") { showAddStudents = true }
                        .font(.subheadline.weight(.semibold))
                }
                .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(roster.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Rename class") { showRename = true }
                    Button("Start a new round") { startNewRound(roster) }
                    Button("Reset call counts") { showResetStatsConfirm = true }
                    Button("Delete class", role: .destructive) { showDeleteConfirm = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddStudents) {
            AddStudentsSheet { single, bulk in
                addStudents(single: single, bulk: bulk, to: roster)
            }
        }
        .sheet(isPresented: $showRename) {
            AddRosterSheet(mode: .rename(current: roster.name)) { newName in
                store.renameRoster(id: roster.id, name: newName)
                return roster.id
            }
        }
        .confirmationDialog(
            "Reset all call counts for this class?",
            isPresented: $showResetStatsConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset call counts", role: .destructive) {
                store.resetStats(rosterId: roster.id)
                resetPickerDisplay()
                showToastMessage("Call counts reset")
            }
        }
        .alert("Delete \"\(roster.name)\"?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteRoster(id: roster.id)
                dismiss()
            }
        } message: {
            Text("This can't be undone.")
        }
        .overlay(alignment: .bottom) {
            if showToast {
                ToastView(message: toastMessage)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showToast)
    }

    // MARK: - Picker card

    private func pickerCard(for roster: Roster) -> some View {
        VStack(spacing: 16) {
            Text(progressText(for: roster))
                .font(.caption)
                .foregroundStyle(.secondary)

            Group {
                if hasPicked {
                    VStack(spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 32, weight: .heavy))
                            .multilineTextAlignment(.center)
                        if !isPicking, lastPickedTimesCalled > 1 {
                            Text("Called \(lastPickedTimesCalled) times total")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandIndigo)
                        }
                    }
                } else {
                    Text("Tap the button to pick a student")
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 90)
            .padding(.horizontal, 8)

            Button {
                pick(from: roster)
            } label: {
                Label("Pick a Student", systemImage: "square.stack.3d.up.fill")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(LinearGradient.brand)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(isPicking ? 0.7 : 1)
            .disabled(isPicking)

            if roster.calledThisRoundCount > 0 {
                Button("Start a new round") {
                    startNewRound(roster)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var studentsEmptyState: some View {
        VStack(spacing: 10) {
            Text("🧑‍🎓").font(.system(size: 36))
            Text("No students yet").font(.headline)
            Text("Add names one at a time, or paste a whole list.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add students") { showAddStudents = true }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandIndigo)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    // MARK: - Actions

    private func sortedStudents(_ roster: Roster) -> [Student] {
        roster.students.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func progressText(for roster: Roster) -> String {
        let total = roster.presentStudents.count
        if total == 0 { return "No students yet" }
        return "\(roster.calledThisRoundCount) of \(total) called this round"
    }

    private func pick(from roster: Roster) {
        guard !isPicking else { return }
        let present = roster.presentStudents
        guard !present.isEmpty else {
            showToastMessage(roster.students.isEmpty ? "Add some students first" : "Everyone is marked absent")
            return
        }

        isPicking = true
        hasPicked = true

        Task { @MainActor in
            for _ in 0..<12 {
                displayName = present.randomElement()?.name ?? ""
                try? await Task.sleep(nanoseconds: 55_000_000)
            }
            if let result = store.pickStudent(rosterId: roster.id) {
                displayName = result.student.name
                lastPickedTimesCalled = result.student.timesCalled
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if result.startedNewRound {
                    showToastMessage("New round started — everyone had been called!")
                }
            }
            isPicking = false
        }
    }

    private func startNewRound(_ roster: Roster) {
        store.startNewRound(rosterId: roster.id)
        resetPickerDisplay()
        showToastMessage("New round started")
    }

    private func resetPickerDisplay() {
        hasPicked = false
        displayName = ""
        lastPickedTimesCalled = 0
    }

    private func addStudents(single: String, bulk: String, to roster: Roster) {
        var names: [String] = []
        let trimmedSingle = single.trimmingCharacters(in: .whitespaces)
        if !trimmedSingle.isEmpty { names.append(trimmedSingle) }
        let bulkNames = bulk
            .components(separatedBy: CharacterSet(charactersIn: "\n,"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        names.append(contentsOf: bulkNames)
        guard !names.isEmpty else { return }

        let added = store.addStudents(rosterId: roster.id, names: names)
        showToastMessage(added > 0 ? "Added \(added) student\(added == 1 ? "" : "s")" : "Those students are already on the list")
    }

    private func showToastMessage(_ text: String) {
        toastTask?.cancel()
        toastMessage = text
        showToast = true
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if !Task.isCancelled {
                showToast = false
            }
        }
    }
}

private struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(.regularMaterial, in: Capsule())
            .shadow(radius: 8, y: 4)
            .padding(.horizontal, 32)
    }
}

#Preview {
    let store = RosterStore()
    let roster = store.addRoster(name: "Period 3 — Chemistry")
    store.addStudents(rosterId: roster.id, names: ["Alex Kim", "Jordan Lee", "Sam Patel"])
    return NavigationStack {
        RosterDetailView(rosterId: roster.id)
    }
    .environmentObject(store)
}
