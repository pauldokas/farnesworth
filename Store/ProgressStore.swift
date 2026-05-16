import Foundation
import SwiftData
import Observation

@Model
public final class UserProgress {
    public var unlockedCount: Int

    public init(unlockedCount: Int = 2) {
        self.unlockedCount = unlockedCount
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
        } else {
            let newProgress = UserProgress(unlockedCount: count)
            modelContext.insert(newProgress)
            currentProgress = newProgress
        }
        try? modelContext.save()
    }
}
