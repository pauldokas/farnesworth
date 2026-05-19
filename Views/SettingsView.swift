import SwiftUI

public struct SettingsView: View {
    @Bindable var timingModel: MorseTimingModel
    @Bindable var audioEngine: MorseAudioEngine

    @AppStorage("appAppearance") private var appAppearance: String = "System"
    let appearanceOptions = ["System", "Light", "Dark"]

    public init(timingModel: MorseTimingModel, audioEngine: MorseAudioEngine) {
        self.timingModel = timingModel
        self.audioEngine = audioEngine
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text("Tone Pitch: \(Int(audioEngine.tonePitch)) Hz")
                        .font(.headline)
                    Slider(value: $audioEngine.tonePitch, in: 400...1000, step: 10) {
                        Text("Tone Pitch")
                    } minimumValueLabel: {
                        Text("400")
                    } maximumValueLabel: {
                        Text("1k")
                    }
                    .accessibilityValue("\(Int(audioEngine.tonePitch)) hertz")
                    .accessibilityHint("Adjusts the frequency of the Morse code tones.")
                }
                .padding(.vertical, 4)
            } header: {
                Text("Audio")
            } footer: {
                Text("Adjust the frequency of the Morse code tones.")
            }

            Section {
                Toggle("Haptic Feedback", isOn: $audioEngine.isHapticsEnabled)
            } header: {
                Text("Feedback")
            }

            Section {
                Picker("Theme", selection: $appAppearance) {
                    ForEach(appearanceOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } header: {
                Text("Appearance")
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Character Speed: \(Int(timingModel.characterSpeed)) WPM")
                        .font(.headline)
                    Slider(value: $timingModel.characterSpeed, in: 10...40, step: 1) {
                        Text("Character Speed")
                    } minimumValueLabel: {
                        Text("10")
                    } maximumValueLabel: {
                        Text("40")
                    }
                    .accessibilityValue("\(Int(timingModel.characterSpeed)) words per minute")
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading) {
                    Text("Effective Speed: \(Int(timingModel.effectiveSpeed)) WPM")
                        .font(.headline)
                    Slider(value: $timingModel.effectiveSpeed, in: 5...30, step: 1) {
                        Text("Effective Speed")
                    } minimumValueLabel: {
                        Text("5")
                    } maximumValueLabel: {
                        Text("30")
                    }
                    .accessibilityValue("\(Int(timingModel.effectiveSpeed)) words per minute")
                }
                .padding(.vertical, 4)
            } header: {
                Text("Farnsworth Speeds")
            } footer: {
                Text("Character speed determines how fast individual letters are played. Effective speed determines the overall speed by adding extra space between characters and words.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(timingModel: MorseTimingModel(), audioEngine: MorseAudioEngine())
    }
}
