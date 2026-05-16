import SwiftUI
import SwiftData

@main
struct FarnsworthApp: App {
    @State private var timingModel = MorseTimingModel()
    @State private var audioEngine = MorseAudioEngine()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(timingModel)
                .environment(audioEngine)
        }
        .modelContainer(for: UserProgress.self)
    }
}
