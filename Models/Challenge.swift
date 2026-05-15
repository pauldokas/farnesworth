import Foundation

public struct Challenge: Identifiable, Hashable {
    public let id: UUID
    public let text: String
    public let morseCode: String
    public let answer: String
    
    public init(text: String, morseCode: String, answer: String? = nil) {
        self.id = UUID()
        self.text = text
        self.morseCode = morseCode
        self.answer = answer ?? text
    }
}
