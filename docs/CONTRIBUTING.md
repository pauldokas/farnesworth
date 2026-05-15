# Contributing

We welcome contributions to the Farnsworth Morse Code app! Our goal is to maintain a simple, robust, and accessible application.

## Development Workflow

1. Create a feature branch (`git checkout -b feature/your-feature`).
2. Ensure your changes compile via `swift build` or `xcodebuild`.
3. Test your changes, especially focusing on edge cases in the `DrillSession` state machine or audio playback.
4. Commit your changes using conventional commits (e.g., `feat: add new haptic pattern`, `fix: audio popping on iOS 17.2`).
5. Open a Pull Request.

## Coding Standards

### Architecture
- **SwiftUI First**: Always prefer SwiftUI. If a bridge to UIKit is needed, clearly document why.
- **Modern Concurrency**: Use `async/await` and `Task` over completion handlers or GCD (`DispatchQueue`).
- **State Management**: Use iOS 17 `@Observable` macro. Avoid legacy Combine property wrappers.

### Audio & Performance
- The `ToneGenerator`'s `renderBlock` is called on a real-time audio thread. **Never** allocate memory, use locks, or call Objective-C runtime methods inside this block. Use pre-allocated ring buffers or atomic variables.

### Accessibility
- All new UI components must be accessible. Add `accessibilityLabel`, `accessibilityHint`, and use `AccessibilityNotification.Announcement` for status changes where appropriate.
- Test your changes with VoiceOver enabled on a physical device.

## Pull Request Review Process
- PRs will be reviewed for code quality, adherence to modern Swift practices, and accessibility.
- Please include a video or screenshot in your PR if your changes affect the UI or UX.