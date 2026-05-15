import Foundation
import AVFoundation
import Observation

/// Manages the AVAudioEngine and AVAudioSession for Morse code playback.
@Observable
public final class MorseAudioEngine {
    private let engine = AVAudioEngine()
    private let sourceNode: AVAudioSourceNode
    private let toneGenerator: ToneGenerator
    private let hapticEngine = HapticEngine()
    
    public private(set) var isRunning = false
    
    public var isHapticsEnabled: Bool {
        get { hapticEngine.isEnabled }
        set { hapticEngine.isEnabled = newValue }
    }
    
    public init() {
#if os(iOS)
        let sampleRate = AVAudioSession.sharedInstance().sampleRate > 0 
            ? AVAudioSession.sharedInstance().sampleRate 
            : 44100.0
#else
        let sampleRate = 44100.0
#endif
        
        self.toneGenerator = ToneGenerator(sampleRate: sampleRate)
        self.sourceNode = AVAudioSourceNode(renderBlock: toneGenerator.renderBlock)
        
        setupEngine()
        setupNotifications()
    }
    
    private func setupEngine() {
        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: outputFormat)
        
        engine.prepare()
    }
    
    private func setupNotifications() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification: notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification: notification)
        }
#endif
    }
    
    public func start() throws {
#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true, options: [])
#endif
        
        try engine.start()
        isRunning = true
    }
    
    public func stop() {
        engine.stop()
        toneGenerator.stop()
        hapticEngine.stop()
        isRunning = false
        
#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [])
#endif
    }
    
    /// Plays a sequence of Morse code elements.
    /// - Parameter sequence: A list of (isTone, duration) pairs.
    public func play(sequence: [(isTone: Bool, duration: Double)]) {
        if !isRunning {
            try? start()
        }
        toneGenerator.enqueue(sequence: sequence)
        hapticEngine.play(sequence: sequence)
    }
    
    private func handleInterruption(notification: Notification) {
#if os(iOS)
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            engine.pause()
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? engine.start()
                }
            }
        }
#endif
    }
    
    private func handleRouteChange(notification: Notification) {
#if os(iOS)
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        if reason == .oldDeviceUnavailable {
            stop()
        }
#endif
    }
}
