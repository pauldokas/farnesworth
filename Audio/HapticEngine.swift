import Foundation
import CoreHaptics
import Observation
import os

/// Manages the CHHapticEngine for tactile feedback synchronized with Morse code.
@MainActor
@Observable
public final class HapticEngine {
    private var engine: CHHapticEngine?
    private var activePlayer: CHHapticPatternPlayer?
    public var isEnabled: Bool = true
    private let logger = Logger(subsystem: "com.example.Farnsworth", category: "HapticEngine")

    public init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            engine?.stoppedHandler = { [weak self] reason in
                self?.logger.warning("Haptic engine stopped: \(String(describing: reason))")
            }

            engine?.resetHandler = { [weak self] in
                self?.logger.info("Haptic engine reset")
                do {
                    try self?.engine?.start()
                } catch {
                    self?.logger.error("Failed to restart haptic engine: \(error.localizedDescription, privacy: .public)")
                }
            }
        } catch {
            logger.error("Failed to start haptic engine: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Plays a sequence of haptic pulses.
    /// - Parameter sequence: A list of (isTone, duration) pairs.
    public func play(sequence: [(isTone: Bool, duration: Double)], delay: TimeInterval = 0) {
        guard isEnabled, let engine = engine else { return }

        stop()

        var events: [CHHapticEvent] = []
        var relativeTime: TimeInterval = 0

        for element in sequence {
            if element.isTone {
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: relativeTime,
                    duration: element.duration
                )
                events.append(event)
            }
            relativeTime += element.duration
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            activePlayer = try engine.makePlayer(with: pattern)
            try activePlayer?.start(atTime: CHHapticTimeImmediate + delay)
        } catch {
            logger.error("Failed to play haptic pattern: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func stop() {
        do {
            try activePlayer?.cancel()
            activePlayer = nil
        } catch {
            logger.error("Failed to cancel haptic player: \(error.localizedDescription, privacy: .public)")
        }
    }
}
