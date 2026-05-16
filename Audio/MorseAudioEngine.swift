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
        set {
            hapticEngine.isEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "isHapticsEnabled")
        }
    }

    public var tonePitch: Double = UserDefaults.standard.object(forKey: "tonePitch") as? Double ?? 600.0 {
        didSet {
            UserDefaults.standard.set(tonePitch, forKey: "tonePitch")
            toneGenerator.setFrequency(tonePitch)
        }
    }

    private var notificationObservers: [Any] = []

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
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

        if let savedHaptics = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool {
            self.hapticEngine.isEnabled = savedHaptics
        }

        self.toneGenerator.setFrequency(self.tonePitch)

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
        let interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification: notification)
        }
        notificationObservers.append(interruptionObserver)

        let routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification: notification)
        }
        notificationObservers.append(routeChangeObserver)
#endif
    }

    public func start() throws {
#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try session.setActive(true, options: [])
#endif

        engine.prepare()
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
            do {
                try start()
            } catch {
                return
            }
        }

        var latency: TimeInterval = 0.0
#if os(iOS)
        if AVAudioSession.sharedInstance().currentRoute.outputs.first != nil {
            latency = AVAudioSession.sharedInstance().outputLatency
        }
#endif

        toneGenerator.enqueue(sequence: sequence)
        hapticEngine.play(sequence: sequence, delay: latency)
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
            isRunning = false
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? engine.start()
                    isRunning = true
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
