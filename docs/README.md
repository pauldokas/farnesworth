# Farnsworth Morse Code Learner

A modern, minimalist iOS application designed to teach Morse Code using the highly effective Farnsworth and Koch methods. Built purely with Swift 5.9, SwiftUI, and AVFoundation.

## Overview
The Farnsworth method helps you learn Morse Code by sending individual characters at a fast target speed (e.g., 20 words per minute) while keeping the spacing between characters and words artificially long (e.g., 15 WPM). This prevents the brain from counting "dots and dashes" and instead trains it to recognize the rhythm and melody of each character.

## Features
- **Koch Method Progression**: Learn two letters first, then incrementally add one new letter at a time once you reach 90% accuracy.
- **Sample-Accurate Audio Synthesis**: `AVAudioEngine` with 5ms S-curve envelopes to prevent audio clicking.
- **Type-Ahead Support**: Built for speed. Type the character while it's playing; the app buffers it seamlessly.
- **Tactile Learning**: `CoreHaptics` feedback mirrors the audio tones for sensory reinforcement.
- **Accessible Design**: Fully VoiceOver compatible with a distraction-free custom keyboard interface.

## Quick Start
1. Ensure you have **Xcode 15+** installed.
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
3. Generate the Xcode project:
   ```bash
   xccodegen generate
   ```
4. Open `Farnsworth.xcodeproj` and run on an iOS 17+ Simulator or Device.

## Documentation
- [Architecture](ARCHITECTURE.md) - System design and audio math
- [Developer Guide](DEVELOPER_GUIDE.md) - Project setup and commands
- [User Guide](USER_GUIDE.md) - How to use the app and methodology
- [Contributing](CONTRIBUTING.md) - PR process and coding standards
