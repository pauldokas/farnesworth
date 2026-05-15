import Foundation
import AVFoundation
import os

public final class ToneGenerator {
    private struct MorseEvent {
        var isTone: Bool
        var samples: Int32
    }
    
    private struct RenderContext {
        var bufferSize: Int32
        var events: UnsafeMutablePointer<MorseEvent>
        var readIndex: Int32
        var writeIndex: Int32
        var currentEventIsTone: Bool
        var currentEventRemainingSamples: Int32
        var currentEventTotalSamples: Int32
        var phase: Double
        var frequency: Double
        var sampleRate: Double
        var envelopeDuration: Double
        var isStopped: Bool
    }
    
    private let sampleRate: Double
    private let bufferSize: Int32 = 8192
    private var producerLock = os_unfair_lock()
    
    private let contextPointer: UnsafeMutablePointer<RenderContext>
    
    public init(sampleRate: Double) {
        self.sampleRate = sampleRate
        
        let eventsPointer = UnsafeMutablePointer<MorseEvent>.allocate(capacity: Int(bufferSize))
        eventsPointer.initialize(repeating: MorseEvent(isTone: false, samples: 0), count: Int(bufferSize))
        
        self.contextPointer = UnsafeMutablePointer<RenderContext>.allocate(capacity: 1)
        self.contextPointer.initialize(to: RenderContext(
            bufferSize: bufferSize,
            events: eventsPointer,
            readIndex: 0,
            writeIndex: 0,
            currentEventIsTone: false,
            currentEventRemainingSamples: 0,
            currentEventTotalSamples: 0,
            phase: 0.0,
            frequency: 600.0,
            sampleRate: sampleRate,
            envelopeDuration: 0.005,
            isStopped: false
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
        
        if context.pointee.isStopped {
            context.pointee.isStopped = false
        }
        
        for event in sequence {
            let samples = Int32(event.duration * sampleRate)
            let nextWriteIndex = (context.pointee.writeIndex + 1) % bufferSize
            
            if nextWriteIndex != context.pointee.readIndex {
                context.pointee.events[Int(context.pointee.writeIndex)] = MorseEvent(isTone: event.isTone, samples: samples)
                context.pointee.writeIndex = nextWriteIndex
            }
        }
    }
    
    public var renderBlock: AVAudioSourceNodeRenderBlock {
        let ctxPtr = self.contextPointer
        
        return { (isSilence, timestamp, frameCount, outputData) -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            guard let buffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            if ctxPtr.pointee.isStopped {
                ctxPtr.pointee.readIndex = ctxPtr.pointee.writeIndex
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
                    if ctxPtr.pointee.readIndex != ctxPtr.pointee.writeIndex {
                        let event = ctxPtr.pointee.events[Int(ctxPtr.pointee.readIndex)]
                        ctxPtr.pointee.currentEventIsTone = event.isTone
                        ctxPtr.pointee.currentEventRemainingSamples = event.samples
                        ctxPtr.pointee.currentEventTotalSamples = event.samples
                        ctxPtr.pointee.readIndex = (ctxPtr.pointee.readIndex + 1) % ctxPtr.pointee.bufferSize
                    } else {
                        ctxPtr.pointee.currentEventIsTone = false
                        ctxPtr.pointee.currentEventRemainingSamples = 0
                        ctxPtr.pointee.currentEventTotalSamples = 0
                    }
                }
                
                var sample: Float = 0.0
                if ctxPtr.pointee.currentEventIsTone && ctxPtr.pointee.currentEventRemainingSamples > 0 {
                    sample = Float(sin(ctxPtr.pointee.phase))
                    ctxPtr.pointee.phase += 2.0 * .pi * ctxPtr.pointee.frequency / ctxPtr.pointee.sampleRate
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
        os_unfair_lock_lock(&producerLock)
        contextPointer.pointee.isStopped = true
        os_unfair_lock_unlock(&producerLock)
    }
}
