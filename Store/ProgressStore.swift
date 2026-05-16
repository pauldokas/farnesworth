import Foundation
import SwiftData
import Observation

@Model
public final class UserProgress {
    public var unlockedCount: Int = 2
    public var activeCharacters: [String] = []

    public init(unlockedCount: Int = 2, activeCharacters: [String]? = nil) {
        self.unlockedCount = unlockedCount
        if let active = activeCharacters {
            self.activeCharacters = active
        } else {
            let initialChars = ["K", "M", "R", "S", "U", "A", "P", "T", "L", "O",
                                "W", "I", ".", "N", "J", "E", "F", "0", "Y", "V",
                                "G", "5", "/", "Q", "9", "Z", "H", "3", "8", "B",
                                "?", "4", "2", "7", "C", "1", "D", "6", "X"]
            self.activeCharacters = Array(initialChars.prefix(max(2, unlockedCount)))
        }
    }
}

@Observable
public final class ProgressStore {
    private var modelContext: ModelContext

    public var currentProgress: UserProgress?

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchProgress()
    }

    public func fetchProgress() {
        let descriptor = FetchDescriptor<UserProgress>()
        do {
            let results = try modelContext.fetch(descriptor)
            if let first = results.first {
                if first.activeCharacters.isEmpty {
                    let initialChars = ["K", "M", "R", "S", "U", "A", "P", "T", "L", "O",
                                        "W", "I", ".", "N", "J", "E", "F", "0", "Y", "V",
                                        "G", "5", "/", "Q", "9", "Z", "H", "3", "8", "B",
                                        "?", "4", "2", "7", "C", "1", "D", "6", "X"]
                    first.activeCharacters = Array(initialChars.prefix(max(2, first.unlockedCount)))
                }
                currentProgress = first
            } else {
                let newProgress = UserProgress(unlockedCount: 2)
                modelContext.insert(newProgress)
                currentProgress = newProgress
            }
        } catch {
            print("Failed to fetch progress: \(error)")
        }
    }

    public func updateUnlockedCount(_ count: Int) {
        if let progress = currentProgress {
            progress.unlockedCount = count
            let initialChars = ["K", "M", "R", "S", "U", "A", "P", "T", "L", "O",
                                "W", "I", ".", "N", "J", "E", "F", "0", "Y", "V",
                                "G", "5", "/", "Q", "9", "Z", "H", "3", "8", "B",
                                "?", "4", "2", "7", "C", "1", "D", "6", "X"]
            if count <= initialChars.count {
                let newChar = initialChars[count - 1]
                if !progress.activeCharacters.contains(newChar) {
                    progress.activeCharacters.append(newChar)
                }
            }
        } else {
            let newProgress = UserProgress(unlockedCount: count)
            modelContext.insert(newProgress)
            currentProgress = newProgress
        }
        try? modelContext.save()
    }

    public func toggleCharacterActive(_ character: String) {
        guard let progress = currentProgress else { return }

        if progress.activeCharacters.contains(character) {
            if progress.activeCharacters.count > 1 {
                progress.activeCharacters.removeAll { $0 == character }
            }
        } else {
            progress.activeCharacters.append(character)
        }
        try? modelContext.save()
    }
}
