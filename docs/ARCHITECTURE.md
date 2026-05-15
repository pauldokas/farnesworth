# Architecture

The application is built using a modern MVVM-inspired state-driven architecture powered by SwiftUI's `@Observable`.

## Directory Structure
- `Models/`: Core timing math and Koch method sequence logic.
- `Audio/`: Low-latency audio synthesis and system disruption handling.
- `Store/`: Global app state and persistence via SwiftData.
- `Views/`: SwiftUI interface layer.

## 1. Farnsworth Timing Math (`MorseTimingModel.swift`)
The app uses the standard PARIS 50-unit timing algorithm.
- **Character Speed (Wc)**: Controls the speed of individual dots and dashes.
- **Effective Speed (We)**: Controls the overall words-per-minute by padding inter-character and inter-word spacing.

**Validation Guardrail**: The effective speed ($W_e$) can never exceed the character speed ($W_c$).

## 2. Precision Audio Engine (`MorseAudioEngine.swift`)
Instead of playing pre-recorded audio files, the app synthesizes a 600Hz sine wave in real-time.
- Uses `AVAudioEngine` and `AVAudioSourceNode` to guarantee sample-accurate timing.
- **Envelopes**: A 5ms cosine (S-curve) attack and release ramp is applied to every tone. This prevents speaker "popping" or "clicking" artifacts caused by instantaneous amplitude shifts.
- **Thread Safety**: Render blocks operate on high-priority audio threads using lock-free data structures.

## 3. Drill State Machine (`DrillSession.swift`)
A state machine manages the learning loop:
1. `idle`: Waiting for user to start.
2. `playingAudio`: Synthesizing and playing the Morse challenge.
3. `awaitingInput`: Audio finished, waiting for keyboard input.
4. `feedback`: Displaying correct/incorrect status.

**Type-Ahead Buffering**: The state machine includes an `inputBuffer`. If a user types the correct character during the `playingAudio` state (a "grace period"), the app immediately queues the `feedback` transition once the audio naturally finishes.

## 4. Haptics
`CoreHaptics` (`HapticEngine.swift`) runs synchronously with the audio engine to provide tactile pulses for dots and dashes, reinforcing the learning loop and providing accessibility support.
