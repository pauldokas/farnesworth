import Foundation
import Observation

@Observable
public class MorseTimingModel {
    public var characterSpeed: Double {
        didSet {
            if characterSpeed.isNaN { characterSpeed = 5.0 }
            if characterSpeed < 5.0 { characterSpeed = 5.0 }
            if characterSpeed > 100.0 { characterSpeed = 100.0 }
            if effectiveSpeed > characterSpeed {
                effectiveSpeed = characterSpeed
            }
        }
    }
    
    public var effectiveSpeed: Double {
        didSet {
            if effectiveSpeed.isNaN { effectiveSpeed = 5.0 }
            if effectiveSpeed < 5.0 { effectiveSpeed = 5.0 }
            if effectiveSpeed > 100.0 { effectiveSpeed = 100.0 }
            if effectiveSpeed > characterSpeed {
                characterSpeed = effectiveSpeed
            }
        }
    }
    
    public init(characterSpeed: Double = 20.0, effectiveSpeed: Double = 15.0) {
        var wc = characterSpeed.isNaN ? 20.0 : characterSpeed
        var we = effectiveSpeed.isNaN ? 15.0 : effectiveSpeed
        
        wc = min(max(wc, 5.0), 100.0)
        we = min(max(we, 5.0), 100.0)
        
        if we > wc {
            wc = we
        }
        
        self.characterSpeed = wc
        self.effectiveSpeed = we
    }
    
    public var dotUnit: Double {
        1.2 / characterSpeed
    }
    
    public var farnsworthUnit: Double {
        // Tf = ((60 / We) - (37.2 / Wc)) / 19
        ((60.0 / effectiveSpeed) - (37.2 / characterSpeed)) / 19.0
    }
    
    public var dashDuration: Double {
        3.0 * dotUnit
    }
    
    public var intraCharacterSpace: Double {
        dotUnit
    }
    
    public var interCharacterSpace: Double {
        3.0 * farnsworthUnit
    }
    
    public var interWordSpace: Double {
        7.0 * farnsworthUnit
    }
}
