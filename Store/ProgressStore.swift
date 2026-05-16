import Foundation
import SwiftData
import Observation
import os

@Model
public final class UserProgress {
    public var unlockedCount: Int = 2
    public var activeCharacters: [String] = []

    public init(unlockedCount: Int = 2, activeCharacters: [String]? = nil) {
        self.unlockedCount = unlockedCount
        if let active = activeCharacters {
            self.activeCharacters = active
        } else {
            let initialChars = LessonProgression.kochSequenceStrings
            self.activeCharacters = Array(initialChars.prefix(max(2, unlockedCount)))
        }
    }
}

@MainActor
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
                    let initialChars = LessonProgression.kochSequenceStrings
                    first.activeCharacters = Array(initialChars.prefix(max(2, first.unlockedCount)))
                }
                currentProgress = first
            } else {
                let newProgress = UserProgress(unlockedCount: 2)
                modelContext.insert(newProgress)
                currentProgress = newProgress
            }
        } catch {
            let logger = Logger(subsystem: "com.example.Farnsworth", category: "ProgressStore")
            logger.error("Failed to fetch progress: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func updateUnlockedCount(_ count: Int) {
        if let progress = currentProgress {
            progress.unlockedCount = count
            let initialChars = LessonProgression.kochSequenceStrings
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
        do {
            try modelContext.save()
        } catch {
            let logger = Logger(subsystem: "com.example.Farnsworth", category: "ProgressStore")
            logger.error("Failed to save progress in updateUnlockedCount: \(error.localizedDescription, privacy: .public)")
        }
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
        do {
            try modelContext.save()
        } catch {
            let logger = Logger(subsystem: "com.example.Farnsworth", category: "ProgressStore")
            logger.error("Failed to save progress in toggleCharacterActive: \(error.localizedDescription, privacy: .public)")
        }
    }
}
