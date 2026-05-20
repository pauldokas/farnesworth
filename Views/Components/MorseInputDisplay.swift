import SwiftUI

struct MorseInputDisplay: View {
    let text: String
    var isCorrect: Bool?

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(size: 60, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(borderColor, lineWidth: 4)
            )
            .onChange(of: isCorrect) { _, newValue in
                if let state = newValue {
                    let announcement = state ? "Correct" : "Incorrect"
                    AccessibilityNotification.Announcement(announcement).post()
                }
            }
    }

    private var backgroundColor: Color {
        guard let state = isCorrect else {
            return Color.secondary.opacity(0.1)
        }
        return state ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
    }

    private var borderColor: Color {
        guard let state = isCorrect else {
            return Color.clear
        }
        return state ? Color.green : Color.red
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "K"
        @State private var state: Bool?

        var body: some View {
            VStack(spacing: 40) {
                MorseInputDisplay(text: text, isCorrect: state)
                    .padding()

                HStack(spacing: 20) {
                    Button("Neutral") { state = nil }
                    Button("Correct") { state = true }
                    Button("Incorrect") { state = false }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    return PreviewWrapper()
}
