import Foundation
import Observation

@Observable
public class MorseTimingModel {
    private var isUpdating = false

    public var characterSpeed: Double {
        didSet {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }

            var newChar = characterSpeed
            if newChar.isNaN { newChar = 5.0 }
            if newChar < 5.0 { newChar = 5.0 }
            if newChar > 100.0 { newChar = 100.0 }

            if effectiveSpeed > newChar {
                effectiveSpeed = newChar
            }
            if characterSpeed != newChar {
                characterSpeed = newChar
            }
            UserDefaults.standard.set(characterSpeed, forKey: "characterSpeed")
        }
    }

    public var effectiveSpeed: Double {
        didSet {
            guard !isUpdating else { return }
            isUpdating = true
            defer { isUpdating = false }

            var newEff = effectiveSpeed
            if newEff.isNaN { newEff = 5.0 }
            if newEff < 5.0 { newEff = 5.0 }
            if newEff > 100.0 { newEff = 100.0 }

            if newEff > characterSpeed {
                characterSpeed = newEff
            }
            if effectiveSpeed != newEff {
                effectiveSpeed = newEff
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
