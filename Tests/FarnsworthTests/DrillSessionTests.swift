import XCTest
import SwiftData
@testable import Farnsworth

@MainActor
final class DrillSessionTests: XCTestCase {
    var session: DrillSession!
    var timingModel: MorseTimingModel!
    var audioEngine: MorseAudioEngine!
    var progressStore: ProgressStore!
    var container: ModelContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        timingModel = MorseTimingModel(characterSpeed: 100, effectiveSpeed: 100)
        audioEngine = MorseAudioEngine()

        let schema = Schema([UserProgress.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: UserProgress.self, configurations: modelConfiguration)
        progressStore = ProgressStore(modelContext: container.mainContext)
        progressStore.updateUnlockedCount(2)

        session = DrillSession(progressStore: progressStore, timingModel: timingModel, audioEngine: audioEngine)
    }

    func testInitialState() {
        XCTAssertEqual(session.currentState, .idle)
        XCTAssertNil(session.currentChallenge)
        XCTAssertEqual(session.inputBuffer, "")
        XCTAssertNil(session.isCorrect)
    }

    func testStartChallenge() {
        session.startNextChallenge()
        XCTAssertEqual(session.currentState, .playingAudio)
        XCTAssertNotNil(session.currentChallenge)
        XCTAssertEqual(session.inputBuffer, "")
        XCTAssertNil(session.isCorrect)
    }

    func testInputSanitization() {
        session.inputBuffer = "k"
        XCTAssertEqual(session.inputBuffer, "K")

        session.inputBuffer = "k1!"
        XCTAssertEqual(session.inputBuffer, "K1!")
    }

    func testCorrectInput() async throws {
        session.startNextChallenge()
        let challenge = try XCTUnwrap(session.currentChallenge)

        session.submitInput(challenge.text)

        try? await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(session.isCorrect, true)
        XCTAssertEqual(session.currentState, .feedback)
    }

    func testIncorrectInput() async throws {
        session.startNextChallenge()
        let challenge = try XCTUnwrap(session.currentChallenge)
        let wrongChar = challenge.text == "K" ? "M" : "K"

        session.submitInput(wrongChar)

        try? await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(session.isCorrect, false)
        XCTAssertEqual(session.currentState, .feedback)
    }

    func testKeyboardUnlocking() throws {
        XCTAssertEqual(session.unlockedCharacters, ["K", "M"])

        let schema = Schema([UserProgress.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProgress.self, configurations: modelConfiguration)
        let newProgressStore = ProgressStore(modelContext: container.mainContext)
        newProgressStore.updateUnlockedCount(5)

        let newSession = DrillSession(progressStore: newProgressStore, timingModel: timingModel, audioEngine: audioEngine)
        XCTAssertEqual(newSession.unlockedCharacters, ["K", "M", "R", "S", "U"])
    }
}
