import Foundation

struct LessonProgression {
    static let kochSequence: [Character] = [
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
    
    var unlockedCount: Int
    
    init(unlockedCount: Int = 2) {
        self.unlockedCount = max(2, min(unlockedCount, LessonProgression.kochSequence.count))
    }
    
    var unlockedCharacters: [Character] {
        Array(LessonProgression.kochSequence.prefix(unlockedCount))
    }
    
    func nextChallenge() -> Challenge {
        let character = unlockedCharacters.randomElement() ?? "K"
        let morse = LessonProgression.morseMapping[character] ?? ""
        return Challenge(text: String(character), morseCode: morse)
    }
}
