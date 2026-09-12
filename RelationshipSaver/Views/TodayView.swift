import SwiftUI

/// The resurface stack. One person at a time, a handful at most, then done.
struct TodayView: View {

    @Environment(Store.self) private var store
    @State private var showingCapture = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingCapture = true
                        } label: {
                            Label("Capture", systemImage: "square.and.pencil")
                        }
                    }
                }
                .sheet(isPresented: $showingCapture) {
                    QuickCaptureView()
                }
                .onAppear {
                    if store.sessionID == nil {
                        store.startSession()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let card = store.currentCard {
            VStack(spacing: 0) {
                SessionProgressView(total: store.session.count, index: store.sessionIndex)
                    .padding(.top, 8)
                CardView(card: card)
                    .id(card.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .animation(.snappy(duration: 0.25), value: store.sessionIndex)
        } else if store.isSessionFinished {
            SessionCompleteView(actedOn: store.completedThisSession)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
            Text("Nothing needs you today")
                .font(.title3.weight(.medium))
            Text("You are up to date with everyone you are tracking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if store.activePeople.isEmpty {
                NavigationLink("Add your first person") {
                    PersonEditView(person: nil)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Quiet progress. Dots, not a counter, and nothing that looks like a score.
struct SessionProgressView: View {

    let total: Int
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(total, 1), id: \.self) { position in
                Capsule()
                    .fill(position <= index ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: position == index ? 20 : 8, height: 6)
                    .animation(.snappy, value: index)
            }
        }
        .accessibilityLabel("Card \(index + 1) of \(total)")
    }
}
