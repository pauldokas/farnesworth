# Developer Guide

## Prerequisites
- macOS 14+
- Xcode 15+ (Swift 5.9+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Project Setup
This project uses XcodeGen to generate the `.xcodeproj` to avoid git merge conflicts on project files.

1. Clone the repository.
2. Run XcodeGen:
   ```bash
   xccodegen generate
   ```
3. Open `Farnsworth.xcodeproj`.
4. Select the **Farnsworth** scheme and an iOS 17 Simulator.
5. Hit `Cmd + R` to build and run.

## Code Organization
The codebase heavily relies on iOS 17 features, specifically the `@Observable` macro and SwiftData.

- **DO NOT** use `@StateObject` or `@ObservedObject` from the Combine framework. Use `@State` and `@Bindable` with `@Observable` classes.
- **DO NOT** use UIKit components unless absolutely necessary (e.g., if a specific hardware-level audio/haptic bridging is required). SwiftUI is the default.

## Testing
To run the tests:
```bash
xcodebuild test -scheme Farnsworth -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Debugging Audio
If audio cuts out:
1. Ensure `AVAudioSession` handles interruptions correctly (see `MorseAudioEngine.swift`).
2. Verify you aren't blocking the `AVAudioSourceNode` render block. Memory allocation or locks inside the render block will cause audio glitching.