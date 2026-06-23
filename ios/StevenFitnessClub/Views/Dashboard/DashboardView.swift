import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var dataStore: WorkoutDataStore
    @EnvironmentObject var analytics: AnalyticsEngine
    @EnvironmentObject var insights: InsightsEngine
    @EnvironmentObject var healthKit: HealthKitService
    @State private var period: TimePeriod = .weekly

    private var periodWorkouts: [WorkoutActivity] {
        dataStore.workouts(in: period)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SFC.Spacing.lg) {
                    header
                    PeriodPicker(selection: $period)
                    metricsGrid
                    performanceScores
                    chartsSection
                    heatmapSection
                }
                .padding(SFC.Spacing.md)
            }
            .background(SFC.Color.deepBlack.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppLogoBanner()
                        .frame(height: 36)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(dataStore.isSyncing ? 360 : 0))
                            .animation(
                                dataStore.isSyncing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: dataStore.isSyncing
                            )
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ciao, Atleta")
                    .font(SFC.Font.title(22))
                if let sync = healthKit.lastSyncDate {
                    Text("Sync: \(sync.formatted(date: .omitted, time: .shortened))")
                        .font(SFC.Font.caption())
                        .foregroundStyle(SFC.Color.textTertiary)
                }
            }
            Spacer()
            AppLogoView(size: 52)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SFC.Spacing.md) {
            MetricCard(
                title: "Distanza", value: String(format: "%.1f", totalDistance),
                unit: "km", icon: "map.fill", accent: SFC.Color.electricBlue,
                trend: analytics.performanceMetrics.weeklyChangePercent.map { String(format: "%+.0f%%", $0) },
                trendUp: (analytics.performanceMetrics.weeklyChangePercent ?? 0) >= 0
            )
            MetricCard(
                title: "Allenamenti", value: "\(periodWorkouts.count)",
                unit: "", icon: "flame.fill", accent: SFC.Color.energyOrange
            )
            MetricCard(
                title: "Calorie", value: String(format: "%.0f", totalCalories),
                unit: "kcal", icon: "bolt.fill", accent: SFC.Color.energyOrange
            )
            MetricCard(
                title: "Durata", value: formatHours(totalDuration),
                unit: "ore", icon: "clock.fill", accent: SFC.Color.performanceGreen
            )
        }
    }

    private var performanceScores: some View {
        VStack(spacing: SFC.Spacing.md) {
            HStack(spacing: SFC.Spacing.md) {
                ScoreRing(
                    title: "Performance",
                    value: analytics.performanceMetrics.performanceScore,
                    max: 100, color: SFC.Color.performanceGreen
                )
                ScoreRing(
                    title: "Training Load",
                    value: analytics.performanceMetrics.trainingLoad,
                    max: 150, color: SFC.Color.electricBlue
                )
                ScoreRing(
                    title: "Stress",
                    value: analytics.performanceMetrics.stressScore,
                    max: 100, color: SFC.Color.energyOrange
                )
            }

            if let vo2 = analytics.performanceMetrics.vo2MaxEstimate {
                HStack {
                    Image(systemName: "lungs.fill")
                        .foregroundStyle(SFC.Color.performanceGreen)
                    Text("VO₂ Max stimato: \(String(format: "%.1f", vo2)) ml/kg/min")
                        .font(SFC.Font.headline(14))
                    Spacer()
                    Label(analytics.performanceMetrics.trendDirection.label, systemImage: analytics.performanceMetrics.trendDirection.icon)
                        .font(SFC.Font.caption())
                        .foregroundStyle(SFC.Color.performanceGreen)
                }
                .padding(SFC.Spacing.md)
                .sfcCard(accent: SFC.Color.performanceGreen)
            }
        }
    }

    private var chartsSection: some View {
        VStack(spacing: SFC.Spacing.lg) {
            chartCard(title: "Distanza nel tempo", icon: "chart.line.uptrend.xyaxis") {
                DistanceTrendChart(data: analytics.distanceTrend)
                    .frame(height: 180)
            }
            chartCard(title: "Ritmo medio", icon: "speedometer") {
                PaceTrendChart(data: analytics.paceTrend)
                    .frame(height: 160)
            }
            chartCard(title: "Potenza media (Watt)", icon: "bolt.circle") {
                PowerTrendChart(data: analytics.powerTrend)
                    .frame(height: 160)
            }
            chartCard(title: "Frequenza cardiaca", icon: "heart.fill") {
                HeartRateTrendChart(data: analytics.heartRateTrend)
                    .frame(height: 160)
            }
            chartCard(title: "Calorie bruciate", icon: "flame") {
                CaloriesBarChart(data: analytics.caloriesTrend)
                    .frame(height: 140)
            }
        }
    }

    private var heatmapSection: some View {
        chartCard(title: "Heatmap settimanale", icon: "calendar") {
            WeeklyHeatmapChart(cells: analytics.heatmapData)
        }
    }

    private func chartCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SFC.Spacing.md) {
            Label(title, systemImage: icon)
                .font(SFC.Font.headline())
                .foregroundStyle(SFC.Color.textPrimary)
            content()
        }
        .padding(SFC.Spacing.md)
        .sfcCard()
    }

    private var totalDistance: Double { periodWorkouts.compactMap(\.distanceKm).reduce(0, +) }
    private var totalCalories: Double { periodWorkouts.compactMap(\.activeCalories).reduce(0, +) }
    private var totalDuration: TimeInterval { periodWorkouts.map(\.duration).reduce(0, +) }

    private func formatHours(_ seconds: TimeInterval) -> String {
        String(format: "%.1f", seconds / 3600)
    }

    private func refreshData() async {
        await dataStore.syncFromHealthKit(healthKit: healthKit)
        analytics.compute(from: dataStore.workouts)
        insights.generate(workouts: dataStore.workouts, metrics: analytics.performanceMetrics)
    }
}

struct ScoreRing: View {
    let title: String
    let value: Double
    let max: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(value / max, 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: value)
                Text(String(format: "%.0f", value))
                    .font(SFC.Font.metric(18))
            }
            .frame(width: 72, height: 72)
            Text(title)
                .font(SFC.Font.caption(10))
                .foregroundStyle(SFC.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SFC.Spacing.sm)
        .sfcCard(accent: color)
    }
}