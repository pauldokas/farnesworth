import Foundation
import AVFoundation
import os

public final class ToneGenerator {
    private struct MorseEvent {
        var isTone: Bool
        var samples: Int32
    }
    
    private let frequency: Double = 600.0
    private let sampleRate: Double
    private var phase: Double = 0.0
    
    private let envelopeDuration: Double = 0.005
    private let envelopeSamples: Int32
    
    private let bufferSize: Int32 = 1024
    private let events: UnsafeMutablePointer<MorseEvent>
    private var readIndex: Int32 = 0
    private var writeIndex: Int32 = 0
    private var producerLock = os_unfair_lock()
    
    private var currentEventIsTone: Bool = false
    private var currentEventRemainingSamples: Int32 = 0
    private var currentEventTotalSamples: Int32 = 0
    
    public init(sampleRate: Double) {
        self.sampleRate = sampleRate
        self.envelopeSamples = Int32(envelopeDuration * sampleRate)
        self.events = UnsafeMutablePointer<MorseEvent>.allocate(capacity: Int(bufferSize))
        self.events.initialize(repeating: MorseEvent(isTone: false, samples: 0), count: Int(bufferSize))
    }
    
    deinit {
        events.deallocate()
    }
    
    public func enqueue(sequence: [(isTone: Bool, duration: Double)]) {
        os_unfair_lock_lock(&producerLock)
        defer { os_unfair_lock_unlock(&producerLock) }
        
        for event in sequence {
            let samples = Int32(event.duration * sampleRate)
            let nextWriteIndex = (writeIndex + 1) % bufferSize
            
            if nextWriteIndex != readIndex {
                events[Int(writeIndex)] = MorseEvent(isTone: event.isTone, samples: samples)
                writeIndex = nextWriteIndex
            }
        }
    }
    
    public var renderBlock: AVAudioSourceNodeRenderBlock {
        return { [weak self] (isSilence, timestamp, frameCount, outputData) -> OSStatus in
            guard let self = self else { return noErr }
            
            let abl = UnsafeMutableAudioBufferListPointer(outputData)
            guard let buffer = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            for frame in 0..<Int(frameCount) {
                if self.currentEventRemainingSamples <= 0 {
                    if self.readIndex != self.writeIndex {
                        let event = self.events[Int(self.readIndex)]
                        self.currentEventIsTone = event.isTone
                        self.currentEventRemainingSamples = event.samples
                        self.currentEventTotalSamples = event.samples
                        self.readIndex = (self.readIndex + 1) % self.bufferSize
                    } else {
                        self.currentEventIsTone = false
                        self.currentEventRemainingSamples = 0
                        self.currentEventTotalSamples = 0
                    }
                }
                
                var sample: Float = 0.0
                if self.currentEventIsTone && self.currentEventRemainingSamples > 0 {
                    sample = Float(sin(self.phase))
                    self.phase += 2.0 * .pi * self.frequency / self.sampleRate
                    if self.phase >= 2.0 * .pi { self.phase -= 2.0 * .pi }
                    
                    let elapsed = self.currentEventTotalSamples - self.currentEventRemainingSamples
                    let remaining = self.currentEventRemainingSamples
                    
                    var multiplier: Double = 1.0
                    if elapsed < self.envelopeSamples {
                        multiplier = 0.5 * (1.0 - cos(.pi * Double(elapsed) / Double(self.envelopeSamples)))
                    } else if remaining < self.envelopeSamples {
                        multiplier = 0.5 * (1.0 + cos(.pi * Double(self.envelopeSamples - remaining) / Double(self.envelopeSamples)))
                    }
                    sample *= Float(multiplier)
                } else {
                    self.phase = 0.0
                }
                
                buffer[frame] = sample
                if self.currentEventRemainingSamples > 0 {
                    self.currentEventRemainingSamples -= 1
                }
            }
            return noErr
        }
    }
    
    public func stop() {
        os_unfair_lock_lock(&producerLock)
        readIndex = writeIndex
        currentEventRemainingSamples = 0
        os_unfair_lock_unlock(&producerLock)
    }
}
