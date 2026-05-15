# Work Plan: Morse Code Farnsworth App

## 1. Objective & Scope
**Goal**: Build a minimal, simple iOS application (Swift 5.9+, SwiftUI) that teaches Morse code using the Farnsworth method and structured lessons. 
**Input**: Keyboard typing (auto-correct disabled).
**Feedback**: Minimalist, audio-centric.

## 2. Technical Approach & Architecture

### A. State Management (SwiftUI)
- Use `@Observable` for the central `DrillSession` store.
- **State Machine**: Implement a `DrillState` enum (`idle`, `playingAudio`, `awaitingInput`, `feedback`).
- **Type-Ahead Support**: Maintain an `inputBuffer` that captures keystrokes while `playingAudio` is active. Implement a "Grace Period" transition so if the correct answer is buffered during audio, it transitions to `feedback` immediately upon audio completion.

### B. Core Logic (Farnsworth Timing)
- Adhere to the **PARIS 50-unit standard**.
- Ensure Character Speed ($W_c$) $\ge$ Effective Speed ($W_e$).
- **Farnsworth Unit ($T_f$)**: $( (60/W_e) - (37.2/W_c) ) / 19$.
- **Spacing**: Inter-character = $3 \times T_f$, Inter-word = $7 \times T_f$.

### C. Audio Synthesis (AVFoundation)
- **Engine**: `AVAudioEngine` with `AVAudioSourceNode` (sample-accurate synthesis on the render thread).
- **Tone**: Sine wave generator with a 5ms **cosine-shaped** envelope (S-curve) on attack/release to prevent popping and provide natural spectral containment.
- **Thread Safety**: The `renderBlock` runs on a real-time thread. Ensure `MorseTimingModel` state is accessed via lock-free mechanisms (e.g., ring buffer for commands) to prevent audio dropouts.
- **Session**: Configure `AVAudioSession` category to `.playback` (plays even when the device is silenced).
- **Resilience**: Implement observers for `AVAudioSession.interruptionNotification` and `routeChangeNotification` to pause/reset the drill state gracefully.

### D. Accessibility & UX
- Use `AccessibilityNotification.Announcement` for VoiceOver feedback (e.g., "Correct, the letter was K").
- Use `CoreHaptics` to mirror audio tones (promoted to a core feature to reinforce tactile learning and aid hearing-impaired users).
- Disable all "smart" keyboard features on the `TextField`.

## 3. Execution Steps

### Phase 1: Project Setup & Core Logic
- [ ] Create Xcode project (SwiftUI, iOS 17+ target).
- [ ] Implement `MorseTimingModel`: Implement the Farnsworth math ($W_c$, $W_e$, $T_u$, $T_f$ calculations). Add validation to ensure $W_c \ge W_e$.
- [ ] Implement `LessonProgression`: Define the Koch method sequence (K, M, R, S, U, A, P, T, L, O, etc.) and logic to serve `Challenge` objects.

### Phase 2: Audio Engine Synthesis
- [ ] Implement `MorseAudioEngine`: Setup `AVAudioEngine`, `AVAudioSession` (.playback), and `AVAudioSourceNode`.
- [ ] Implement Sine Wave Generator: Inside the render block, calculate samples based on `MorseTimingModel`.
- [ ] Implement Envelopes: Add 5ms attack/release ramps to the render block to prevent audio clicks.
- [ ] Implement Audio Interruption handling (pause engine on calls/disconnects).

### Phase 3: State Management & UI Integration
- [ ] Implement `DrillSession` (`@Observable`): Build the state machine (`idle` -> `playingAudio` -> `awaitingInput` -> `feedback`).
- [ ] Implement `DrillView` (SwiftUI): Create the main UI. Bind to `DrillSession`.
- [ ] Implement `MorseInputTextField`: A custom wrapper or modified `TextField` with `.autocorrectionDisabled()`, `.textInputAutocapitalization(.never)`, and `.keyboardType(.asciiCapable)`.
- [ ] Implement Type-Ahead: Allow keystrokes to buffer even during the `playingAudio` state.

### Phase 4: Persistence & Polish
- [ ] Implement `ProgressStore` (using **SwiftData** for iOS 17+ synergy): Save the user's unlocked characters in the Koch sequence.
- [ ] Implement Settings UI: Allow adjustment of Character Speed ($W_c$) and Effective Speed ($W_e$).
- [ ] Implement VoiceOver announcements for correct/incorrect feedback.

### Phase 5: File Structure Initialization
- `Models/`: `MorseTimingModel.swift`, `Challenge.swift`, `LessonProgression.swift`
- `Audio/`: `MorseAudioEngine.swift`, `ToneGenerator.swift`
- `Views/`: `DrillView.swift`, `SettingsView.swift`, `Components/MorseInputTextField.swift`
- `Store/`: `DrillSession.swift`, `ProgressStore.swift`

## 4. Final Verification Wave
*Must explicitly ask user "okay" before marking project complete.*
- [ ] Verify Farnsworth spacing audibly (fast dots/dashes, long spaces).
- [ ] Verify no audio popping on tone start/stop.
- [ ] Verify keyboard input does not auto-correct or auto-capitalize.
- [ ] Verify audio continues playing when the hardware silent switch is toggled.
- [ ] Verify app handles phone call interruptions gracefully.
