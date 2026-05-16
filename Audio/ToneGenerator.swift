import Foundation
import AVFoundation
import Atomics

public final class ToneGenerator {
    private struct MorseEvent {
        var isTone: Bool
        var samples: Int32
        var frequency: Double
    }

    private struct RenderContext {
        var bufferSize: Int
        var events: UnsafeMutablePointer<MorseEvent>
        var readIndex: ManagedAtomic<Int>
        var writeIndex: ManagedAtomic<Int>
        var currentEventIsTone: Bool
        var currentEventRemainingSamples: Int32
        var currentEventTotalSamples: Int32
        var currentEventFrequency: Double
        var phase: Double
        var sampleRate: Double
        var envelopeDuration: Double
        var isStopped: ManagedAtomic<Bool>
    }

    private let sampleRate: Double
    private let bufferSize: Int = 8192

    private let contextPointer: UnsafeMutablePointer<RenderContext>
    private var currentFrequency: Double = 600.0
    // Lock used ONLY by producer (enqueue and setFrequency), never by consumer
    private var producerLock = os_unfair_lock()

    public init(sampleRate: Double) {
        self.sampleRate = sampleRate

        let eventsPointer = UnsafeMutablePointer<MorseEvent>.allocate(capacity: bufferSize)
        eventsPointer.initialize(repeating: MorseEvent(isTone: false, samples: 0, frequency: 600.0), count: bufferSize)

        self.contextPointer = UnsafeMutablePointer<RenderContext>.allocate(capacity: 1)
        self.contextPointer.initialize(to: RenderContext(
            bufferSize: bufferSize,
            events: eventsPointer,
            readIndex: ManagedAtomic<Int>(0),
            writeIndex: ManagedAtomic<Int>(0),
            currentEventIsTone: false,
            currentEventRemainingSamples: 0,
            currentEventTotalSamples: 0,
            currentEventFrequency: 600.0,
            phase: 0.0,
            sampleRate: sampleRate,
            envelopeDuration: 0.005,
            isStopped: ManagedAtomic<Bool>(false)
        ))
    }

    deinit {
        contextPointer.pointee.events.deallocate()
        contextPointer.deallocate()
    }

    public func enqueue(sequence: [(isTone: Bool, duration: Double)]) {
        os_unfair_lock_lock(&producerLock)
        defer { os_unfair_lock_unlock(&producerLock) }

        let context = contextPointer

        if context.pointee.isStopped.load(ordering: .relaxed) {
            context.pointee.isStopped.store(false, ordering: .relaxed)
        }

        let frequency = self.currentFrequency

        for event in sequence {
            let samples = Int32(event.duration * sampleRate)
            let currentWrite = context.pointee.writeIndex.load(ordering: .relaxed)
            let nextWriteIndex = (currentWrite + 1) % bufferSize
            let currentRead = context.pointee.readIndex.load(ordering: .acquiring)

            if nextWriteIndex != currentRead {
                context.pointee.events[currentWrite] = MorseEvent(isTone: event.isTone, samples: samples, frequency: frequency)
                context.pointee.writeIndex.store(nextWriteIndex, ordering: .releasing)
            }
        }
    }

    public func setFrequency(_ frequency: Double) {
        os_unfair_lock_lock(&producerLock)
        self.currentFrequency = frequency
        os_unfair_lock_unlock(&producerLock)
    }

    public var renderBlock: AVAudioSourceNodeRenderBlock {
        let ctxPtr = self.contextPointer

        return { (_, _, frameCount, outputData) -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            guard let buffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            if ctxPtr.pointee.isStopped.load(ordering: .relaxed) {
                let writeIdx = ctxPtr.pointee.writeIndex.load(ordering: .relaxed)
                ctxPtr.pointee.readIndex.store(writeIdx, ordering: .relaxed)
                ctxPtr.pointee.currentEventRemainingSamples = 0
                ctxPtr.pointee.currentEventTotalSamples = 0
                ctxPtr.pointee.currentEventIsTone = false

                for frame in 0..<Int(frameCount) {
                    buffer[frame] = 0.0
                }
                return noErr
            }

            for frame in 0..<Int(frameCount) {
                if ctxPtr.pointee.currentEventRemainingSamples <= 0 {
                    let readIdx = ctxPtr.pointee.readIndex.load(ordering: .relaxed)
                    let writeIdx = ctxPtr.pointee.writeIndex.load(ordering: .acquiring)

                    if readIdx != writeIdx {
                        let event = ctxPtr.pointee.events[readIdx]
                        ctxPtr.pointee.currentEventIsTone = event.isTone
                        ctxPtr.pointee.currentEventRemainingSamples = event.samples
                        ctxPtr.pointee.currentEventTotalSamples = event.samples
                        ctxPtr.pointee.currentEventFrequency = event.frequency

                        let nextReadIndex = (readIdx + 1) % ctxPtr.pointee.bufferSize
                        ctxPtr.pointee.readIndex.store(nextReadIndex, ordering: .releasing)
                    } else {
                        ctxPtr.pointee.currentEventIsTone = false
                        ctxPtr.pointee.currentEventRemainingSamples = 0
                        ctxPtr.pointee.currentEventTotalSamples = 0
                    }
                }

                var sample: Float = 0.0
                if ctxPtr.pointee.currentEventIsTone && ctxPtr.pointee.currentEventRemainingSamples > 0 {
                    sample = Float(sin(ctxPtr.pointee.phase))
                    ctxPtr.pointee.phase += 2.0 * .pi * ctxPtr.pointee.currentEventFrequency / ctxPtr.pointee.sampleRate
                    if ctxPtr.pointee.phase >= 2.0 * .pi { ctxPtr.pointee.phase -= 2.0 * .pi }

                    let elapsed = ctxPtr.pointee.currentEventTotalSamples - ctxPtr.pointee.currentEventRemainingSamples
                    let remaining = ctxPtr.pointee.currentEventRemainingSamples

                    var envelopeSamples = Int32(ctxPtr.pointee.envelopeDuration * ctxPtr.pointee.sampleRate)
                    if ctxPtr.pointee.currentEventTotalSamples < envelopeSamples * 2 {
                        envelopeSamples = max(1, ctxPtr.pointee.currentEventTotalSamples / 2)
                    }

                    var multiplier: Double = 1.0
                    if elapsed < envelopeSamples {
                        multiplier = 0.5 * (1.0 - cos(.pi * Double(elapsed) / Double(envelopeSamples)))
                    } else if remaining < envelopeSamples {
                        multiplier = 0.5 * (1.0 + cos(.pi * Double(envelopeSamples - remaining) / Double(envelopeSamples)))
                    }
                    sample *= Float(multiplier)
                } else {
                    ctxPtr.pointee.phase = 0.0
                }

                buffer[frame] = sample
                if ctxPtr.pointee.currentEventRemainingSamples > 0 {
                    ctxPtr.pointee.currentEventRemainingSamples -= 1
                }
            }
            return noErr
        }
    }

    public func stop() {
        contextPointer.pointee.isStopped.store(true, ordering: .relaxed)
    }
}
