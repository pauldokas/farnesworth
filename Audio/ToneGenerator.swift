import Foundation
import AVFoundation
import Atomics

public final class ToneGenerator {
    private struct MorseEvent {
        var isTone: Bool
        var samples: Int32
        var frequency: Double
    }

    private final class RenderContext {
        let bufferSize: Int
        let events: UnsafeMutablePointer<MorseEvent>
        let readIndex: UnsafeAtomic<Int>
        let writeIndex: UnsafeAtomic<Int>
        var currentEventIsTone: Bool
        let currentEventRemainingSamples: UnsafeAtomic<Int32>
        var currentEventTotalSamples: Int32
        var currentEventFrequency: Double
        var phase: Double
        let sampleRate: Double
        let envelopeDuration: Double
        let isStopped: UnsafeAtomic<Bool>

        init(sampleRate: Double, bufferSize: Int) {
            self.sampleRate = sampleRate
            self.bufferSize = bufferSize
            self.events = UnsafeMutablePointer<MorseEvent>.allocate(capacity: bufferSize)
            self.events.initialize(repeating: MorseEvent(isTone: false, samples: 0, frequency: 600.0), count: bufferSize)
            self.readIndex = UnsafeAtomic<Int>.create(0)
            self.writeIndex = UnsafeAtomic<Int>.create(0)
            self.currentEventIsTone = false
            self.currentEventRemainingSamples = UnsafeAtomic<Int32>.create(0)
            self.currentEventTotalSamples = 0
            self.currentEventFrequency = 600.0
            self.phase = 0.0
            self.envelopeDuration = 0.005
            self.isStopped = UnsafeAtomic<Bool>.create(false)
        }

        deinit {
            readIndex.destroy()
            writeIndex.destroy()
            currentEventRemainingSamples.destroy()
            isStopped.destroy()
            events.deallocate()
        }
    }

    private let sampleRate: Double
    private let bufferSize: Int = 65536

    private let context: RenderContext
    private var currentFrequency: Double = 600.0
    // Lock used ONLY by producer (enqueue and setFrequency), never by consumer
    private let producerLock = NSLock()

    public init(sampleRate: Double) {
        self.sampleRate = sampleRate
        self.context = RenderContext(sampleRate: sampleRate, bufferSize: bufferSize)
    }

    public func enqueue(sequence: [(isTone: Bool, duration: Double)]) {
        producerLock.lock()
        defer { producerLock.unlock() }

        let ctx = context
        let frequency = self.currentFrequency

        for event in sequence {
            let samples = Int32(event.duration * sampleRate)
            let currentWrite = ctx.writeIndex.load(ordering: .relaxed)
            let nextWriteIndex = (currentWrite + 1) % bufferSize
            let currentRead = ctx.readIndex.load(ordering: .acquiring)

            if nextWriteIndex != currentRead {
                ctx.events[currentWrite] = MorseEvent(isTone: event.isTone, samples: samples, frequency: frequency)
                ctx.writeIndex.store(nextWriteIndex, ordering: .releasing)
            } else {
                #if DEBUG
                print("ToneGenerator buffer overflow. Dropping events. Increase buffer size or chunk data.")
                #endif
                break
            }
        }
    }

    public func setFrequency(_ frequency: Double) {
        producerLock.lock()
        self.currentFrequency = frequency
        producerLock.unlock()
    }

    public var isPlaybackComplete: Bool {
        let readIdx = context.readIndex.load(ordering: .relaxed)
        let writeIdx = context.writeIndex.load(ordering: .relaxed)
        let remaining = context.currentEventRemainingSamples.load(ordering: .relaxed)
        return readIdx == writeIdx && remaining <= 0
    }

    public var renderBlock: AVAudioSourceNodeRenderBlock {
        let ctx = self.context

        return { (_, _, frameCount, outputData) -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            guard let buffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            for frame in 0..<Int(frameCount) {
                if ctx.isStopped.load(ordering: .relaxed) {
                    buffer[frame] = 0.0
                    continue
                }

                var remaining = ctx.currentEventRemainingSamples.load(ordering: .relaxed)
                if remaining <= 0 {
                    let readIdx = ctx.readIndex.load(ordering: .relaxed)
                    let writeIdx = ctx.writeIndex.load(ordering: .acquiring)

                    if readIdx != writeIdx {
                        let event = ctx.events[readIdx]
                        ctx.currentEventIsTone = event.isTone
                        remaining = event.samples
                        ctx.currentEventRemainingSamples.store(remaining, ordering: .relaxed)
                        ctx.currentEventTotalSamples = event.samples
                        ctx.currentEventFrequency = event.frequency

                        let nextReadIndex = (readIdx + 1) % ctx.bufferSize
                        ctx.readIndex.store(nextReadIndex, ordering: .releasing)
                    } else {
                        ctx.currentEventIsTone = false
                        ctx.currentEventTotalSamples = 0
                    }
                }

                var sample: Float = 0.0
                if ctx.currentEventIsTone && remaining > 0 {
                    sample = Float(sin(ctx.phase))
                    ctx.phase += 2.0 * .pi * ctx.currentEventFrequency / ctx.sampleRate
                    if ctx.phase >= 2.0 * .pi { ctx.phase -= 2.0 * .pi }

                    let elapsed = ctx.currentEventTotalSamples - remaining

                    var envelopeSamples = Int32(ctx.envelopeDuration * ctx.sampleRate)
                    if ctx.currentEventTotalSamples < envelopeSamples * 2 {
                        envelopeSamples = max(1, ctx.currentEventTotalSamples / 2)
                    }

                    var multiplier: Double = 1.0
                    if elapsed < envelopeSamples {
                        multiplier = 0.5 * (1.0 - cos(.pi * Double(elapsed) / Double(envelopeSamples)))
                    } else if remaining < envelopeSamples {
                        multiplier = 0.5 * (1.0 + cos(.pi * Double(envelopeSamples - remaining) / Double(envelopeSamples)))
                    }
                    sample *= Float(multiplier)
                } else {
                    ctx.phase = 0.0
                }

                buffer[frame] = sample
                if remaining > 0 {
                    remaining -= 1
                    ctx.currentEventRemainingSamples.store(remaining, ordering: .relaxed)
                }
            }
            return noErr
        }
    }

    public func stop() {
        producerLock.lock()
        defer { producerLock.unlock() }

        context.isStopped.store(true, ordering: .relaxed)
        let currentRead = context.readIndex.load(ordering: .relaxed)
        context.writeIndex.store(currentRead, ordering: .relaxed)
        context.currentEventRemainingSamples.store(0, ordering: .relaxed)
        context.isStopped.store(false, ordering: .relaxed)
    }
}
