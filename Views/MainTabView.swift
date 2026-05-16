import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(MorseTimingModel.self) private var timingModel
    @Environment(MorseAudioEngine.self) private var audioEngine

    var body: some View {
        TabView {
            DrillView()
                .tabItem {
                    Label("Drill", systemImage: "play.circle.fill")
                }

            NavigationStack {
                ProgressReviewView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                SettingsView(timingModel: timingModel, audioEngine: audioEngine)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(MorseTimingModel())
        .environment(MorseAudioEngine())
        .modelContainer(for: UserProgress.self, inMemory: true)
}
