import Foundation
import CoreHaptics
import Observation

/// Manages the CHHapticEngine for tactile feedback synchronized with Morse code.
@Observable
public final class HapticEngine {
    private var engine: CHHapticEngine?
    public var isEnabled: Bool = true
    
    public init() {
        prepareEngine()
    }
    
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
            
            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset")
                try? self?.engine?.start()
            }
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    /// Plays a sequence of haptic pulses.
    /// - Parameter sequence: A list of (isTone, duration) pairs.
    public func play(sequence: [(isTone: Bool, duration: Double)]) {
        guard isEnabled, let engine = engine else { return }
        
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
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    public func stop() {}
}
