import SwiftUI
import SwiftData

struct ProgressReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressQuery: [UserProgress]

    private var progressStore: ProgressStore {
        ProgressStore(modelContext: modelContext)
    }

    var currentProgress: UserProgress? {
        progressQuery.first
    }

    var unlockedCount: Int {
        min(currentProgress?.unlockedCount ?? 2, LessonProgression.kochSequence.count)
    }

    var activeCharacters: [String] {
        currentProgress?.activeCharacters ?? []
    }

    var inactiveCharacters: [String] {
        let unlocked = Array(LessonProgression.kochSequence.prefix(unlockedCount)).map { String($0) }
        return unlocked.filter { !activeCharacters.contains($0) }
    }

    var lockedCharacters: [String] {
        let locked = Array(LessonProgression.kochSequence.dropFirst(unlockedCount)).map { String($0) }
        return locked
    }

    var progressFraction: CGFloat {
        CGFloat(unlockedCount) / CGFloat(LessonProgression.kochSequence.count)
    }

    var progressPercentage: Int {
        Int(progressFraction * 100)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Koch Sequence")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Level \(unlockedCount) of \(LessonProgression.kochSequence.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(lineWidth: 6)
                            .opacity(0.3)
                            .foregroundColor(.accentColor)

                        Circle()
                            .trim(from: 0.0, to: progressFraction)
                            .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.accentColor)
                            .rotationEffect(Angle(degrees: 270.0))

                        Text("\(progressPercentage)%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .frame(width: 50, height: 50)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Progress: \(progressPercentage) percent")
                }
                .padding(.horizontal)
                .padding(.top, 16)

                if !activeCharacters.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Letters")
                            .font(.headline)
                            .padding(.horizontal)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(activeCharacters, id: \.self) { char in
                                Button(action: {
                                    progressStore.toggleCharacterActive(char)
                                }, label: {
                                    CharacterProgressCell(character: Character(char), state: .active)
                                })
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                if !inactiveCharacters.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Inactive Letters")
                            .font(.headline)
                            .padding(.horizontal)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(inactiveCharacters, id: \.self) { char in
                                Button(action: {
                                    progressStore.toggleCharacterActive(char)
                                }, label: {
                                    CharacterProgressCell(character: Character(char), state: .inactive)
                                })
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                if !lockedCharacters.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Locked Letters")
                            .font(.headline)
                            .padding(.horizontal)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(0..<lockedCharacters.count, id: \.self) { index in
                                let char = lockedCharacters[index]
                                let isNext = index == 0
                                CharacterProgressCell(character: Character(char), state: isNext ? .next : .locked)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
        .navigationTitle("Progress")
    }
}

struct CharacterProgressCell: View {
    enum CellState {
        case active, inactive, next, locked
    }

    let character: Character
    let state: CellState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)

            if state == .next {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }

            Text(String(character))
                .font(.title2)
                .fontWeight(state == .active ? .bold : .medium)
                .foregroundColor(foregroundColor)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityLabel)
    }

    private var backgroundColor: Color {
        switch state {
        case .active:
            return Color.accentColor.opacity(0.15)
        case .inactive:
            return Color.accentColor.opacity(0.05)
        case .next:
            return Color.gray.opacity(0.1)
        case .locked:
            return Color.gray.opacity(0.05)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .active:
            return .primary
        case .inactive:
            return .primary.opacity(0.5)
        case .next:
            return .primary.opacity(0.6)
        case .locked:
            return .secondary.opacity(0.3)
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .active:
            return "\(character), active"
        case .inactive:
            return "\(character), inactive"
        case .next:
            return "\(character), next character to unlock"
        case .locked:
            return "\(character), locked"
        }
    }
}

#Preview {
    NavigationStack {
        ProgressReviewView()
            .modelContainer(for: UserProgress.self, inMemory: true)
    }
}
