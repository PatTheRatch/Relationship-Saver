import SwiftUI

/// Capture before the thought disappears.
///
/// The text field is focused the moment this opens and the person is optional,
/// because a capture that cannot be filed is still worth more than a thought
/// that is gone. Unassigned captures wait in the inbox on the People tab.
struct QuickCaptureView: View {

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var textFieldFocused: Bool

    @State private var text: String = ""
    @State private var kind: CaptureKind = .followUp
    @State private var personID: UUID?
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86_400)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you want to remember?", text: $text, axis: .vertical)
                        .lineLimit(2...5)
                        .focused($textFieldFocused)
                }

                Section("Kind") {
                    Picker("Kind", selection: $kind) {
                        ForEach(CaptureKind.allCases) { option in
                            Label(option.title, systemImage: option.symbolName).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Who") {
                    Picker("Person", selection: $personID) {
                        Text("Decide later").tag(UUID?.none)
                        ForEach(store.activePeople) { person in
                            Text(person.name).tag(UUID?.some(person.id))
                        }
                    }
                }

                if kind.usesDueDate {
                    Section("When to bring it back") {
                        Toggle("Remind me on a date", isOn: $hasDueDate)
                        if hasDueDate {
                            DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { textFieldFocused = true }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // A reply owed is always actionable immediately, so it never carries a
        // due date. A follow up without one surfaces as soon as it is created.
        let due: Date? = (kind.usesDueDate && hasDueDate) ? dueDate : nil

        store.add(Capture(
            personID: personID,
            text: trimmed,
            kind: kind,
            dueAt: kind == .followUp ? (due ?? Date()) : nil
        ))
        dismiss()
    }
}
