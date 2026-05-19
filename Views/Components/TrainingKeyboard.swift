import SwiftUI
import UIKit

struct TrainingKeyboard: View {
    let activeCharacters: [Character]
    var disableInactive: Bool = true
    let onKeyPress: (String) -> Void
    var onBackspace: (() -> Void)?

    private let rows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", "="],
        ["Z", "X", "C", "V", "B", "N", "M", ",", ".", "?", "/"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    if rowIndex == 2 {
                        Spacer(minLength: 10)
                    }
                    ForEach(rows[rowIndex], id: \.self) { charStr in
                        let isActive = activeCharacters.contains(Character(charStr))
                        KeyButton(
                            title: charStr,
                            isActive: isActive,
                            isDisabled: disableInactive && !isActive,
                            action: { onKeyPress(charStr) }
                        )
                    }
                    if rowIndex == 2 {
                        Spacer(minLength: 10)
                    }
                }
            }

            HStack(spacing: 6) {
                KeyButton(
                    title: "Space",
                    isActive: true,
                    isDisabled: false,
                    action: { onKeyPress(" ") }
                )
                .frame(maxWidth: .infinity)

                if let onBackspace = onBackspace {
                    KeyButton(
                        title: "⌫",
                        isActive: true,
                        isDisabled: false,
                        action: { onBackspace() }
                    )
                    .frame(width: 60)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct KeyButton: View {
    let title: String
    let isActive: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }, label: {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isActive ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isActive ? .white : .secondary.opacity(0.5))
                .cornerRadius(8)
        })
        .disabled(isDisabled)
        .accessibilityLabel(title == "⌫" ? "Backspace" : title)
        .accessibilityHint(isActive ? "Tap to input" : (isDisabled ? "Locked" : "Tap to toggle"))
    }
}

#Preview {
    TrainingKeyboard(activeCharacters: ["K", "M", "R", "S", "U", "A", "P", "T", "L", "O"], onKeyPress: { _ in }, onBackspace: {})
        .padding()
}
