import SwiftUI

/// Add or edit a person.
///
/// Name, intent and cadence are the only things asked for. Everything else is
/// optional, and onboarding never asks the user to map out their whole social
/// universe before the app becomes useful.
struct PersonEditView: View {

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let existing: Person?

    @State private var name: String
    @State private var intent: RelationshipIntent
    @State private var cadenceDays: Int
    @State private var phoneNumber: String
    @State private var notes: String
    @State private var hasBirthday: Bool
    @State private var birthday: Date
    @State private var cadenceTouched: Bool

    init(person: Person?) {
        self.existing = person
        _name = State(initialValue: person?.name ?? "")
        _intent = State(initialValue: person?.intent ?? .maintain)
        _cadenceDays = State(initialValue: person?.cadenceDays ?? RelationshipIntent.maintain.suggestedCadenceDays)
        _phoneNumber = State(initialValue: person?.phoneNumber ?? "")
        _notes = State(initialValue: person?.notes ?? "")
        _hasBirthday = State(initialValue: person?.birthday != nil)
        _cadenceTouched = State(initialValue: person != nil)

        var initialBirthday = Date()
        if let monthDay = person?.birthday {
            var components = DateComponents()
            components.year = Calendar.current.component(.year, from: Date())
            components.month = monthDay.month
            components.day = monthDay.day
            initialBirthday = Calendar.current.date(from: components) ?? Date()
        }
        _birthday = State(initialValue: initialBirthday)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            }

            Section("Intent") {
                Picker("Intent", selection: $intent) {
                    ForEach(RelationshipIntent.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(intent.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Cadence") {
                Stepper(value: $cadenceDays, in: 1...365) {
                    Text("Every \(cadenceDays) days")
                }
                .onChange(of: cadenceDays) { _, _ in
                    cadenceTouched = true
                }
                Text("They start coming back softly before this runs out.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Optional") {
                TextField("Phone number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)

                Toggle("Birthday", isOn: $hasBirthday)
                if hasBirthday {
                    DatePicker("Date", selection: $birthday, displayedComponents: .date)
                }

                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            if let existing {
                Section {
                    Button(existing.isArchived ? "Return to rotation" : "Archive") {
                        store.setArchived(!existing.isArchived, for: existing)
                        dismiss()
                    }
                    Button("Delete", role: .destructive) {
                        store.delete(existing)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(existing == nil ? "Add person" : "Edit")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: intent) { _, newValue in
            // Only follow the intent's suggestion while the user has not set a
            // cadence of their own.
            if !cadenceTouched {
                cadenceDays = newValue.suggestedCadenceDays
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let monthDay = hasBirthday ? MonthDay(date: birthday) : nil
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespaces)

        if var person = existing {
            person.name = trimmedName
            person.intent = intent
            person.cadenceDays = cadenceDays
            person.phoneNumber = trimmedPhone.isEmpty ? nil : trimmedPhone
            person.birthday = monthDay
            person.notes = notes
            store.update(person)
        } else {
            store.add(Person(
                name: trimmedName,
                intent: intent,
                cadenceDays: cadenceDays,
                phoneNumber: trimmedPhone.isEmpty ? nil : trimmedPhone,
                birthday: monthDay,
                notes: notes
            ))
        }
        dismiss()
    }
}
