import SwiftUI

struct DrillView: View {
    @State private var session = DrillSession(
        lessonProgression: LessonProgression(),
        timingModel: MorseTimingModel(),
        audioEngine: MorseAudioEngine()
    )
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            if session.currentState == .idle {
                Button(action: {
                    session.startNextChallenge()
                }) {
                    Text("Start Drill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
            } else {
                VStack(spacing: 24) {
                    Text(statusText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(statusAccessibilityLabel)
                        .accessibilityAddTraits(.updatesFrequently)
                    
                    MorseInputTextField(
                        text: Binding(
                            get: { session.inputBuffer },
                            set: { newValue in
                                if newValue.count > session.inputBuffer.count {
                                    let newChars = newValue.dropFirst(session.inputBuffer.count)
                                    for char in newChars {
                                        session.submitInput(String(char))
                                    }
                                } else {
                                    session.inputBuffer = newValue.uppercased()
                                }
                            }
                        ),
                        isCorrect: session.isCorrect
                    )
                    .disabled(session.currentState == .feedback)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .animation(.easeInOut, value: session.currentState)
    }
    
    private var statusText: String {
        switch session.currentState {
        case .idle:
            return "Ready"
        case .playingAudio:
            return "Listen..."
        case .awaitingInput:
            return "Type what you heard"
        case .feedback:
            if let isCorrect = session.isCorrect {
                return isCorrect ? "Correct!" : "Incorrect"
            }
            return "..."
        }
    }
    
    private var statusAccessibilityLabel: String {
        switch session.currentState {
        case .idle:
            return "Ready to start"
        case .playingAudio:
            return "Listening to Morse code"
        case .awaitingInput:
            return "Awaiting your input"
        case .feedback:
            if let isCorrect = session.isCorrect {
                return isCorrect ? "Correct" : "Incorrect"
            }
            return "Feedback"
        }
    }
}

#Preview {
    DrillView()
}
