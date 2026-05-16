import SwiftUI
import SwiftData

struct ProgressReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressQuery: [UserProgress]

    var currentProgress: UserProgress? {
        progressQuery.first
    }

    var unlockedCount: Int {
        min(currentProgress?.unlockedCount ?? 2, LessonProgression.kochSequence.count)
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

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<LessonProgression.kochSequence.count, id: \.self) { index in
                        let char = LessonProgression.kochSequence[index]
                        let isUnlocked = index < unlockedCount
                        let isNext = index == unlockedCount

                        CharacterProgressCell(character: char, isUnlocked: isUnlocked, isNext: isNext)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Progress")
    }
}

struct CharacterProgressCell: View {
    let character: Character
    let isUnlocked: Bool
    let isNext: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)

            if isNext {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }

            Text(String(character))
                .font(.title2)
                .fontWeight(isUnlocked ? .bold : .medium)
                .foregroundColor(foregroundColor)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(isUnlocked ? "\(character), unlocked" : (isNext ? "\(character), next character to unlock" : "\(character), locked"))
    }

    private var backgroundColor: Color {
        if isUnlocked {
            return Color.accentColor.opacity(0.15)
        } else if isNext {
            return Color.gray.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }

    private var foregroundColor: Color {
        if isUnlocked {
            return .primary
        } else if isNext {
            return .primary.opacity(0.6)
        } else {
            return .secondary.opacity(0.3)
        }
    }
}

#Preview {
    NavigationStack {
        ProgressReviewView()
            .modelContainer(for: UserProgress.self, inMemory: true)
    }
}
