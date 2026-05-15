import SwiftUI

struct MorseInputTextField: View {
    @Binding var text: String
    var isCorrect: Bool?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("Type here", text: $text)
            .font(.system(size: 80, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .autocorrectionDisabled()
#if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.asciiCapable)
#endif
            .focused($isFocused)
            .padding(.vertical, 32)
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
            .onAppear {
                isFocused = true
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
        @State private var text = ""
        @State private var state: Bool?
        
        var body: some View {
            VStack(spacing: 40) {
                MorseInputTextField(text: $text, isCorrect: state)
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
