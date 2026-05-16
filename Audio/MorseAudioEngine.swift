import Foundation
import AVFoundation
import Observation
import os

/// Manages the AVAudioEngine and AVAudioSession for Morse code playback.
@MainActor
@Observable
public final class MorseAudioEngine {
    private let engine = AVAudioEngine()
    private let sourceNode: AVAudioSourceNode
    private let toneGenerator: ToneGenerator
    private let hapticEngine = HapticEngine()
    private let logger = Logger(subsystem: "com.example.Farnsworth", category: "MorseAudioEngine")

    public private(set) var isRunning = false

    public var isHapticsEnabled: Bool {
        get { hapticEngine.isEnabled }
        set {
            hapticEngine.isEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "isHapticsEnabled")
        }
    }

    public var isPlaybackComplete: Bool {
        return toneGenerator.isPlaybackComplete
    }

    public var tonePitch: Double {
        didSet {
            if tonePitch.isNaN { tonePitch = 600.0 }
            if tonePitch < 100.0 { tonePitch = 100.0 }
            if tonePitch > 2000.0 { tonePitch = 2000.0 }
            UserDefaults.standard.set(tonePitch, forKey: "tonePitch")
            toneGenerator.setFrequency(tonePitch)
        }
    }

    private final class NotificationTaskTracker: @unchecked Sendable {
        private let lock = NSLock()
        private var tasks: [Task<Void, Never>] = []

        func add(_ task: Task<Void, Never>) {
            lock.lock()
            tasks.append(task)
            lock.unlock()
        }

        deinit {
            lock.lock()
            let currentTasks = tasks
            lock.unlock()
            for task in currentTasks { task.cancel() }
        }
    }

    private let taskTracker = NotificationTaskTracker()

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

        var initialPitch = UserDefaults.standard.object(forKey: "tonePitch") as? Double ?? 600.0
        if initialPitch.isNaN { initialPitch = 600.0 }
        if initialPitch < 100.0 { initialPitch = 100.0 }
        if initialPitch > 2000.0 { initialPitch = 2000.0 }
        self.tonePitch = initialPitch

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
        let interruptionTask = Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance()) {
                guard let self = self else { break }
                self.handleInterruption(notification: notification)
            }
        }

        let routeChangeTask = Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance()) {
                guard let self = self else { break }
                self.handleRouteChange(notification: notification)
            }
        }
        taskTracker.add(interruptionTask)
        taskTracker.add(routeChangeTask)
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
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [])
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
        }
#endif
    }

    /// Plays a sequence of Morse code elements.
    /// - Parameter sequence: A list of (isTone, duration) pairs.
    public func play(sequence: [(isTone: Bool, duration: Double)]) -> TimeInterval {
        if !isRunning {
            do {
                try start()
            } catch {
                logger.error("Failed to start audio engine for playback: \(error.localizedDescription, privacy: .public)")
                return 0.0
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

        return latency
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
                    do {
                        try engine.start()
                        isRunning = true
                    } catch {
                        logger.error("Failed to resume audio engine after interruption: \(error.localizedDescription, privacy: .public)")
                    }
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
