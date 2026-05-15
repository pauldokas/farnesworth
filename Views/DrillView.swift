import SwiftUI

struct DrillView: View {
    @Environment(MorseTimingModel.self) private var timingModel
    @Environment(MorseAudioEngine.self) private var audioEngine
    
    @State private var session: DrillSession?
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            if session?.currentState == .idle || session == nil {
                Button(action: {
                    if session == nil {
                        session = DrillSession(
                            lessonProgression: LessonProgression(),
                            timingModel: timingModel,
                            audioEngine: audioEngine
                        )
                    }
                    session?.startNextChallenge()
                }, label: {
                    Text("Start Drill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                })
                .padding(.horizontal, 32)
            } else if let session = session {
                VStack(spacing: 24) {
                    Text(statusText(for: session))
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(statusAccessibilityLabel(for: session))
                        .accessibilityAddTraits(.updatesFrequently)
                    
                    MorseInputTextField(
                        text: Bindable(session).inputBuffer,
                        isCorrect: session.isCorrect
                    )
                    .disabled(session.currentState == .feedback)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .animation(.easeInOut, value: session?.currentState)
    }
    
    private func statusText(for session: DrillSession) -> String {
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
    
    private func statusAccessibilityLabel(for session: DrillSession) -> String {
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
        .environment(MorseTimingModel())
        .environment(MorseAudioEngine())
}
