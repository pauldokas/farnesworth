import Foundation

struct Challenge: Identifiable, Hashable {
    let id: UUID
    let text: String
    let morseCode: String
    let answer: String
    
    init(text: String, morseCode: String, answer: String? = nil) {
        self.id = UUID()
        self.text = text
        self.morseCode = morseCode
        self.answer = answer ?? text
    }
}
