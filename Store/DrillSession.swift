import Foundation
import Observation

@MainActor
@Observable
public final class DrillSession {
    public enum DrillState {
        case idle
        case playingAudio
        case awaitingInput
        case feedback
    }

    public var currentState: DrillState = .idle
    public var currentChallenge: Challenge?

    public var inputBuffer: String = "" {
        didSet {
            let sanitized = inputBuffer.uppercased().filter { $0.isASCII }
            if inputBuffer != sanitized {
                inputBuffer = sanitized
            }

            if currentState == .awaitingInput {
                validateInput()
            }
        }
    }

    public var isCorrect: Bool?

    public var unlockedCharacters: [Character] {
        lessonProgression.unlockedCharacters
    }

    private var lessonProgression: LessonProgression
    private let progressStore: ProgressStore
    private let timingModel: MorseTimingModel
    private let audioEngine: MorseAudioEngine

    private var playbackTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var recentResults: [Bool] = []

    public init(progressStore: ProgressStore, timingModel: MorseTimingModel, audioEngine: MorseAudioEngine) {
        self.progressStore = progressStore
        self.lessonProgression = LessonProgression(unlockedCount: progressStore.currentProgress?.unlockedCount ?? 2)
        self.timingModel = timingModel
        self.audioEngine = audioEngine
    }

    public func startNextChallenge() {
        feedbackTask?.cancel()
        playbackTask?.cancel()
        audioEngine.stop()

        let challenge = lessonProgression.nextChallenge()
        currentChallenge = challenge
        inputBuffer = ""
        isCorrect = nil
        currentState = .playingAudio

        let sequence = convertMorseToSequence(challenge.morseCode)
        let totalDuration = sequence.reduce(0.0) { $0 + $1.duration }

        audioEngine.play(sequence: sequence)

        playbackTask = Task {
            try? await Task.sleep(for: .seconds(totalDuration))

            guard !Task.isCancelled else { return }

            if inputBuffer == currentChallenge?.text {
                isCorrect = true
                recordResult(true)
                transitionToFeedback()
            } else {
                currentState = .awaitingInput
                if inputBuffer.count >= (currentChallenge?.text.count ?? Int.max) {
                    validateInput()
                }
            }
        }
    }

    public func submitInput(_ char: String) {
        guard currentState == .awaitingInput || currentState == .playingAudio else { return }
        inputBuffer += char
    }

    public func backspaceInput() {
        guard currentState == .awaitingInput || currentState == .playingAudio else { return }
        if !inputBuffer.isEmpty {
            inputBuffer.removeLast()
        }
    }

    private func validateInput() {
        guard let challenge = currentChallenge else { return }

        if inputBuffer == challenge.text {
            isCorrect = true
            recordResult(true)
            transitionToFeedback()
        } else if inputBuffer.count >= challenge.text.count {
            isCorrect = false
            recordResult(false)
            transitionToFeedback()
        }
    }

    private func recordResult(_ correct: Bool) {
        recentResults.append(correct)
        if recentResults.count > 20 {
            recentResults.removeFirst()
        }

        if recentResults.count == 20 {
            let correctCount = recentResults.filter { $0 }.count
            let accuracy = Double(correctCount) / 20.0
            if accuracy >= 0.90 {
                let currentCount = progressStore.currentProgress?.unlockedCount ?? 2
                if currentCount < LessonProgression.kochSequence.count {
                    let newCount = currentCount + 1
                    progressStore.updateUnlockedCount(newCount)
                    lessonProgression = LessonProgression(unlockedCount: newCount)
                    recentResults.removeAll()
                }
            }
        }
    }

    private func transitionToFeedback() {
        currentState = .feedback

        feedbackTask = Task {
            try? await Task.sleep(for: .seconds(1.5))

            guard !Task.isCancelled else { return }

            startNextChallenge()
        }
    }

    private func convertMorseToSequence(_ morse: String) -> [(isTone: Bool, duration: Double)] {
        var sequence: [(isTone: Bool, duration: Double)] = []
        let words = morse.components(separatedBy: "   ")

        for (wordIndex, word) in words.enumerated() {
            let chars = word.components(separatedBy: " ")

            for (charIndex, charStr) in chars.enumerated() {
                let elements = Array(charStr)
                for (elemIndex, element) in elements.enumerated() {
                    if element == "." {
                        sequence.append((isTone: true, duration: timingModel.dotUnit))
                    } else if element == "-" {
                        sequence.append((isTone: true, duration: timingModel.dashDuration))
                    }

                    if elemIndex < elements.count - 1 {
                        sequence.append((isTone: false, duration: timingModel.intraCharacterSpace))
                    }
                }

                if charIndex < chars.count - 1 {
                    sequence.append((isTone: false, duration: timingModel.interCharacterSpace))
                }
            }

            if wordIndex < words.count - 1 {
                sequence.append((isTone: false, duration: timingModel.interWordSpace))
            }
        }

        return sequence
    }
}
