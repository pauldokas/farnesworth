import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(MorseTimingModel.self) private var timingModel
    @Environment(MorseAudioEngine.self) private var audioEngine

    var body: some View {
        NavigationStack {
            DrillView()
                .navigationTitle("Farnsworth")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            NavigationLink(destination: ProgressReviewView()) {
                                Label("Progress", systemImage: "chart.bar.fill")
                            }
                            NavigationLink(destination: SettingsView(timingModel: timingModel, audioEngine: audioEngine)) {
                                Label("Settings", systemImage: "gearshape.fill")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .imageScale(.large)
                                .accessibilityLabel("Menu")
                        }
                    }
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
