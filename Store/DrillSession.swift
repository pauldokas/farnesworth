import Foundation
import Observation

@Observable
final class DrillSession {
    enum DrillState {
        case idle
        case playingAudio
        case awaitingInput
        case feedback
    }
    
    var currentState: DrillState = .idle
    var currentChallenge: Challenge?
    var inputBuffer: String = ""
    var isCorrect: Bool?
    
    private var lessonProgression: LessonProgression
    private let timingModel: MorseTimingModel
    private let audioEngine: MorseAudioEngine
    
    private var gracePeriodCorrect = false
    private var playbackTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    
    init(lessonProgression: LessonProgression, timingModel: MorseTimingModel, audioEngine: MorseAudioEngine) {
        self.lessonProgression = lessonProgression
        self.timingModel = timingModel
        self.audioEngine = audioEngine
    }
    
    func startNextChallenge() {
        feedbackTask?.cancel()
        playbackTask?.cancel()
        
        let challenge = lessonProgression.nextChallenge()
        currentChallenge = challenge
        inputBuffer = ""
        isCorrect = nil
        gracePeriodCorrect = false
        currentState = .playingAudio
        
        let sequence = convertMorseToSequence(challenge.morseCode)
        let totalDuration = sequence.reduce(0.0) { $0 + $1.duration }
        
        audioEngine.play(sequence: sequence)
        
        playbackTask = Task {
            try? await Task.sleep(for: .seconds(totalDuration))
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                if gracePeriodCorrect {
                    isCorrect = true
                    transitionToFeedback()
                } else {
                    currentState = .awaitingInput
                    if !inputBuffer.isEmpty {
                        validateInput()
                    }
                }
            }
        }
    }
    
    func submitInput(_ char: String) {
        let upperChar = char.uppercased()
        inputBuffer += upperChar
        
        if currentState == .playingAudio {
            if inputBuffer == currentChallenge?.text {
                gracePeriodCorrect = true
            }
        } else if currentState == .awaitingInput {
            validateInput()
        }
    }
    
    private func validateInput() {
        guard let challenge = currentChallenge else { return }
        
        if inputBuffer == challenge.text {
            isCorrect = true
            transitionToFeedback()
        } else if inputBuffer.count >= challenge.text.count {
            isCorrect = false
            transitionToFeedback()
        }
    }
    
    private func transitionToFeedback() {
        currentState = .feedback
        
        feedbackTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                startNextChallenge()
            }
        }
    }
    
    private func convertMorseToSequence(_ morse: String) -> [(isTone: Bool, duration: Double)] {
        var sequence: [(isTone: Bool, duration: Double)] = []
        let elements = Array(morse)
        
        for (index, element) in elements.enumerated() {
            if element == "." {
                sequence.append((isTone: true, duration: timingModel.dotUnit))
            } else if element == "-" {
                sequence.append((isTone: true, duration: timingModel.dashDuration))
            }
            
            if index < elements.count - 1 {
                sequence.append((isTone: false, duration: timingModel.intraCharacterSpace))
            }
        }
        
        return sequence
    }
}
