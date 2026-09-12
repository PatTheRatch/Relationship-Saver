import SwiftUI
import MessageUI

/// One person, one reason, four things you can do about it.
///
/// The default card stays visually simple. Context is available behind a tap
/// rather than crowding the surface, because the moment this screen starts to
/// look like a dashboard it stops being something the user wants to open.
struct CardView: View {

    let card: SessionCard

    @Environment(Store.self) private var store
    @State private var showingComposer = false
    @State private var showingContext = false

    private var person: Person { card.person }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            header
            Spacer(minLength: 12)
            actions
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .sheet(isPresented: $showingComposer) {
            MessageComposerView(
                recipients: [person.phoneNumber].compactMap { $0 },
                body: ""
            ) { result in
                if result == .sent {
                    store.markConnected(card: card, channel: .message)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingContext) {
            PersonContextView(person: person)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Text(person.name)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(card.reason.cardLine)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if card.reason.isReply {
                Label("They are waiting on you", systemImage: "arrowshape.turn.up.left")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            if person.snoozeCount >= 2 {
                // Mentioned once, gently, and never in a way that blocks
                // snoozing again.
                Text("You have put this one off before")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Button {
                showingContext = true
            } label: {
                Label("Context", systemImage: "info.circle")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                sendMessage()
            } label: {
                Label("Message", systemImage: "message.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                store.markConnected(card: card)
            } label: {
                Label("We connected", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            HStack(spacing: 10) {
                Menu {
                    ForEach(SnoozeDuration.allCases) { duration in
                        Button(duration.title) {
                            store.snooze(card: card, duration: duration)
                        }
                    }
                } label: {
                    Label("Snooze", systemImage: "moon.zzz")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Menu {
                    Button("Skip for now") {
                        store.skip(card: card)
                    }
                    Button("Archive", role: .destructive) {
                        store.archive(card: card)
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private func sendMessage() {
        if person.phoneNumber?.isEmpty == false, MessageComposerView.canSendText {
            showingComposer = true
        } else {
            // No number on file, or the device cannot send. Recording the
            // contact is still the right outcome: the user is about to go and
            // message them somewhere else.
            store.markConnected(card: card)
        }
    }
}

/// Everything about a person that does not belong on the card itself.
struct PersonContextView: View {

    let person: Person

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !person.notes.isEmpty {
                    Section("Notes") {
                        Text(person.notes)
                    }
                }

                let captures = store.openCaptures(for: person)
                if !captures.isEmpty {
                    Section("Captured") {
                        ForEach(captures) { capture in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(capture.text)
                                Text(capture.kind.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Relationship") {
                    LabeledContent("Intent", value: person.intent.title)
                    LabeledContent("Cadence", value: "Every \(person.cadenceDays) days")
                    if let last = person.lastContactedAt {
                        LabeledContent("Last contact", value: last.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        LabeledContent("Last contact", value: "Not recorded yet")
                    }
                }

                Section {
                    NavigationLink("Edit person") {
                        PersonEditView(person: person)
                    }
                }
            }
            .navigationTitle(person.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
