import Foundation

public struct LessonProgression {
    public static let kochSequence: [Character] = [
        "K", "M", "R", "S", "U", "A", "P", "T", "L", "O",
        "W", "I", ".", "N", "J", "E", "F", "0", "Y", "V",
        "G", "5", "/", "Q", "9", "Z", "H", "3", "8", "B",
        "?", "4", "2", "7", "C", "1", "D", "6", "X"
    ]

    private static let morseMapping: [Character: String] = [
        "K": "-.-", "M": "--", "R": ".-.", "S": "...", "U": "..-", "A": ".-",
        "P": ".--.", "T": "-", "L": ".-..", "O": "---", "W": ".--", "I": "..",
        ".": ".-.-.-", "N": "-.", "J": ".---", "E": ".", "F": "..-.", "0": "-----",
        "Y": "-.--", "V": "...-", "G": "--.", "5": ".....", "/": "-..-.", "Q": "--.-",
        "9": "----.", "Z": "--..", "H": "....", "3": "...--", "8": "---..", "B": "-...",
        "?": "..--..", "4": "....-", "2": "..---", "7": "--...", "C": "-.-.", "1": ".----",
        "D": "-..", "6": "-....", "X": "-..-"
    ]

    public var activeCharacters: [Character]

    public init(activeCharacters: [Character]) {
        self.activeCharacters = activeCharacters.isEmpty ? ["K", "M"] : activeCharacters
    }

    public func nextChallenge() -> Challenge {
        let character = activeCharacters.randomElement() ?? "K"
        let morse = LessonProgression.morseMapping[character] ?? ""
        return Challenge(text: String(character), morseCode: morse)
    }
}
