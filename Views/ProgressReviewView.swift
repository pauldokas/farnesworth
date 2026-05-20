import SwiftUI
import SwiftData

struct ProgressReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressQuery: [UserProgress]

    private var progressStore: ProgressStore {
        ProgressStore(modelContext: modelContext)
    }

    var activeCharacters: [String] {
        progressQuery.first?.activeCharacters ?? []
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Select characters to practice in the Drill.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)

                TrainingKeyboard(
                    activeCharacters: activeCharacters.map { Character($0) },
                    disableInactive: false,
                    onKeyPress: { charStr in
                        progressStore.toggleCharacterActive(charStr)
                    }
                )
                .padding(.top, 8)

            Spacer()
        }
        .navigationTitle("Progress")
    }
}

#Preview {
    NavigationStack {
        ProgressReviewView()
            .modelContainer(for: UserProgress.self, inMemory: true)
    }
}
