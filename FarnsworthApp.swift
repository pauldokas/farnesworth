import SwiftUI
import SwiftData
import os

@main
struct FarnsworthApp: App {
    @State private var timingModel = MorseTimingModel()
    @State private var audioEngine = MorseAudioEngine()
    @AppStorage("appAppearance") private var appAppearance: String = "System"

    let container: ModelContainer

    init() {
        do {
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: UserProgress.self, configurations: config)

            Task.detached {
                let fileManager = FileManager.default
                let paths = [
                    storeURL.path,
                    storeURL.path + "-shm",
                    storeURL.path + "-wal"
                ]
                let logger = Logger(subsystem: "com.example.Farnsworth", category: "DataProtection")

                for path in paths where fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: path)
                    } catch {
                        logger.error("Failed to set data protection for \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
        } catch {
            fatalError("Could not initialize SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(timingModel)
                .environment(audioEngine)
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(container)
    }

    private var colorScheme: ColorScheme? {
        switch appAppearance {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
}
