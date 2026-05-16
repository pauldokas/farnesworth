import SwiftUI
import SwiftData

@main
struct FarnsworthApp: App {
    @State private var timingModel = MorseTimingModel()
    @State private var audioEngine = MorseAudioEngine()
    @AppStorage("appAppearance") private var appAppearance: String = "System"

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(timingModel)
                .environment(audioEngine)
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(for: UserProgress.self)
    }

    private var colorScheme: ColorScheme? {
        switch appAppearance {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
}
