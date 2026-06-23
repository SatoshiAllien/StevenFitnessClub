import SwiftUI

struct ActivitiesListView: View {
    @EnvironmentObject var dataStore: WorkoutDataStore
    @State private var selectedSport: SportType?

    private var filtered: [WorkoutActivity] {
        guard let sport = selectedSport else { return dataStore.workouts }
        return dataStore.workouts(for: sport)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sportFilter
                if filtered.isEmpty {
                    emptyState
                } else {
                    List(filtered) { workout in
                        NavigationLink(value: workout) {
                            ActivityRow(workout: workout)
                        }
                        .listRowBackground(SFC.Color.cardBackground)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SFC.Color.deepBlack.ignoresSafeArea())
            .navigationTitle("Attività")
            .navigationDestination(for: WorkoutActivity.self) { workout in
                ActivityDetailView(workout: workout)
            }
        }
    }

    private var sportFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SFC.Spacing.sm) {
                FilterChip(title: "Tutti", isSelected: selectedSport == nil) {
                    selectedSport = nil
                }
                ForEach(SportType.allCases) { sport in
                    FilterChip(
                        title: sport.displayName,
                        icon: sport.icon,
                        isSelected: selectedSport == sport
                    ) { selectedSport = sport }
                }
            }
            .padding(SFC.Spacing.md)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nessuna attività",
            systemImage: "figure.run",
            description: Text("Sincronizza con Apple Salute per importare i tuoi workout.")
        )
    }
}

struct ActivityRow: View {
    let workout: WorkoutActivity

    var body: some View {
        HStack(spacing: SFC.Spacing.md) {
            Image(systemName: workout.sport.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: workout.sport.accentColor))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.sport.displayName)
                    .font(SFC.Font.headline(15))
                Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(SFC.Font.caption())
                    .foregroundStyle(SFC.Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let km = workout.distanceKm {
                    Text(String(format: "%.2f km", km))
                        .font(SFC.Font.headline(14))
                }
                Text(workout.durationFormatted)
                    .font(SFC.Font.caption())
                    .foregroundStyle(SFC.Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(title).font(SFC.Font.caption(13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? SFC.Color.electricBlue : SFC.Color.cardBackground)
            .foregroundStyle(isSelected ? .white : SFC.Color.textSecondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SFC.Color.cardBorder, lineWidth: isSelected ? 0 : 1))
        }
    }
}