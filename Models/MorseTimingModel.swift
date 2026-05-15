import Foundation
import Observation

@Observable
public class MorseTimingModel {
    public var characterSpeed: Double {
        didSet {
            if characterSpeed < effectiveSpeed {
                effectiveSpeed = characterSpeed
            }
        }
    }
    
    public var effectiveSpeed: Double {
        didSet {
            if effectiveSpeed > characterSpeed {
                characterSpeed = effectiveSpeed
            }
        }
    }
    
    public init(characterSpeed: Double = 20.0, effectiveSpeed: Double = 15.0) {
        let wc = max(characterSpeed, effectiveSpeed)
        let we = min(characterSpeed, effectiveSpeed)
        
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
