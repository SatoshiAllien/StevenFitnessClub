import SwiftUI

struct CompareView: View {
    @EnvironmentObject var dataStore: WorkoutDataStore
    @EnvironmentObject var analytics: AnalyticsEngine
    @State private var mode: CompareMode = .periods
    @State private var period: TimePeriod = .monthly
    @State private var workoutA: WorkoutActivity?
    @State private var workoutB: WorkoutActivity?
    @State private var result: ComparisonResult?

    enum CompareMode: String, CaseIterable {
        case periods = "Periodi"
        case workouts = "Attività"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SFC.Spacing.lg) {
                    Picker("Modalità", selection: $mode) {
                        ForEach(CompareMode.allCases, id: \.rawValue) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch mode {
                    case .periods: periodCompare
                    case .workouts: workoutCompare
                    }

                    if let result { comparisonResult(result) }
                }
                .padding(SFC.Spacing.md)
            }
            .background(SFC.Color.deepBlack.ignoresSafeArea())
            .navigationTitle("Confronti")
        }
    }

    private var periodCompare: some View {
        VStack(spacing: SFC.Spacing.md) {
            Text("Confronta periodo corrente vs precedente")
                .font(SFC.Font.caption())
                .foregroundStyle(SFC.Color.textSecondary)
            PeriodPicker(selection: $period)
            Button("Confronta") {
                result = analytics.comparePeriods(period, period, workouts: dataStore.workouts)
            }
            .buttonStyle(SFCButtonStyle())
        }
    }

    private var workoutCompare: some View {
        VStack(spacing: SFC.Spacing.md) {
            workoutPicker("Attività A", selection: $workoutA)
            workoutPicker("Attività B", selection: $workoutB)
            Button("Confronta") {
                guard let a = workoutA, let b = workoutB else { return }
                result = analytics.compareWorkouts(a, b)
            }
            .buttonStyle(SFCButtonStyle())
            .disabled(workoutA == nil || workoutB == nil)
        }
    }

    private func workoutPicker(_ label: String, selection: Binding<WorkoutActivity?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(SFC.Font.caption()).foregroundStyle(SFC.Color.textSecondary)
            Menu {
                ForEach(dataStore.workouts.prefix(30)) { w in
                    Button("\(w.sport.displayName) — \(w.startDate.formatted(date: .abbreviated, time: .omitted))") {
                        selection.wrappedValue = w
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue?.sport.displayName ?? "Seleziona...")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(SFC.Spacing.md)
                .background(SFC.Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: SFC.Radius.md))
            }
        }
    }

    private func comparisonResult(_ result: ComparisonResult) -> some View {
        VStack(alignment: .leading, spacing: SFC.Spacing.md) {
            Text(result.title).font(SFC.Font.headline())
            Text("\(result.periodA) vs \(result.periodB)")
                .font(SFC.Font.caption())
                .foregroundStyle(SFC.Color.textSecondary)

            ForEach(result.metrics) { metric in
                HStack {
                    VStack(alignment: .leading) {
                        Text(metric.name).font(SFC.Font.headline(14))
                        HStack(spacing: 12) {
                            Text(String(format: "%.1f", metric.valueA))
                            Text("→")
                            Text(String(format: "%.1f", metric.valueB))
                        }
                        .font(SFC.Font.caption())
                        .foregroundStyle(SFC.Color.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%+.1f%%", metric.deltaPercent))
                            .font(SFC.Font.headline(14))
                            .foregroundStyle(metric.isImprovement ? SFC.Color.performanceGreen : SFC.Color.energyOrange)
                        Text(metric.unit)
                            .font(SFC.Font.caption(10))
                            .foregroundStyle(SFC.Color.textTertiary)
                    }
                }
                .padding(SFC.Spacing.md)
                .sfcCard(accent: metric.isImprovement ? SFC.Color.performanceGreen : SFC.Color.energyOrange)
            }
        }
    }
}

struct SFCButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SFC.Font.headline())
            .frame(maxWidth: .infinity)
            .padding(SFC.Spacing.md)
            .background(SFC.Color.electricBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: SFC.Radius.md))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}