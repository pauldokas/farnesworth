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
            UserDefaults.standard.set(characterSpeed, forKey: "characterSpeed")
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
            UserDefaults.standard.set(effectiveSpeed, forKey: "effectiveSpeed")
        }
    }

    public init(characterSpeed: Double? = nil, effectiveSpeed: Double? = nil) {
        var charSpeed = characterSpeed ?? UserDefaults.standard.object(forKey: "characterSpeed") as? Double ?? 20.0
        var effSpeed = effectiveSpeed ?? UserDefaults.standard.object(forKey: "effectiveSpeed") as? Double ?? 15.0

        charSpeed = min(max(charSpeed, 5.0), 100.0)
        effSpeed = min(max(effSpeed, 5.0), 100.0)

        if effSpeed > charSpeed {
            charSpeed = effSpeed
        }

        self.characterSpeed = charSpeed
        self.effectiveSpeed = effSpeed
    }

    public var dotUnit: Double {
        1.2 / characterSpeed
    }

    public var farnsworthUnit: Double {
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
