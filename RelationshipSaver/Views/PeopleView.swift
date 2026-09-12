import SwiftUI

struct PeopleView: View {

    @Environment(Store.self) private var store
    @State private var showingCapture = false
    @State private var showingAddPerson = false

    var body: some View {
        NavigationStack {
            List {
                if !store.unassignedCaptures.isEmpty {
                    Section("Waiting to be filed") {
                        ForEach(store.unassignedCaptures) { capture in
                            NavigationLink {
                                AssignCaptureView(capture: capture)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(capture.text)
                                    Text(capture.kind.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("People") {
                    if store.activePeople.isEmpty {
                        Text("Nobody yet. Add the handful of people you most want to stay close to.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.activePeople) { person in
                        NavigationLink {
                            PersonEditView(person: person)
                        } label: {
                            PersonRow(person: person)
                        }
                    }
                }

                if !store.archivedPeople.isEmpty {
                    Section("Archived") {
                        ForEach(store.archivedPeople) { person in
                            NavigationLink {
                                PersonEditView(person: person)
                            } label: {
                                Text(person.name).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingCapture = true
                    } label: {
                        Label("Capture", systemImage: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPerson = true
                    } label: {
                        Label("Add person", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCapture) {
                QuickCaptureView()
            }
            .sheet(isPresented: $showingAddPerson) {
                NavigationStack {
                    PersonEditView(person: nil)
                }
            }
        }
    }
}

struct PersonRow: View {

    let person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(person.name)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        let days = person.daysSinceContact(at: Date())
        let phrase = SurfaceReason.softTimePhrase(days: days)
        if person.isSnoozed(at: Date()) {
            return "Snoozed  ·  \(phrase.lowercased())"
        }
        return "\(person.intent.title)  ·  \(phrase.lowercased())"
    }
}

/// Files an unassigned capture against a person.
struct AssignCaptureView: View {

    let capture: Capture

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var personID: UUID?

    var body: some View {
        Form {
            Section("Capture") {
                Text(capture.text)
                Text(capture.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Who is this about?") {
                Picker("Person", selection: $personID) {
                    Text("Not yet").tag(UUID?.none)
                    ForEach(store.activePeople) { person in
                        Text(person.name).tag(UUID?.some(person.id))
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section {
                Button("Discard this capture", role: .destructive) {
                    store.complete(captureID: capture.id)
                    dismiss()
                }
            }
        }
        .navigationTitle("File capture")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    var updated = capture
                    updated.personID = personID
                    store.update(updated)
                    dismiss()
                }
                .disabled(personID == nil)
            }
        }
    }
}
