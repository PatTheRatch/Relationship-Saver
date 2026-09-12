import SwiftUI

/// The satisfying moment at the end of a short session.
///
/// Small on purpose. The reward is the feeling of being finished, not a badge.
struct SessionCompleteView: View {

    let actedOn: Int

    @Environment(Store.self) private var store
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.tint)
                .scaleEffect(hasAppeared ? 1 : 0.6)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: hasAppeared)

            Text("That's the stack")
                .font(.title2.weight(.semibold))

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Go again") {
                store.startSession()
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { hasAppeared = true }
    }

    private var summary: String {
        switch actedOn {
        case 0: return "Nothing needed doing right now. That counts too."
        case 1: return "You got in touch with one person."
        default: return "You got in touch with \(actedOn) people."
        }
    }
}
