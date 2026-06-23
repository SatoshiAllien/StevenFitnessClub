import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var insights: InsightsEngine
    @EnvironmentObject var analytics: AnalyticsEngine
    @State private var selectedCategory: InsightCategory?

    private var filtered: [AIInsight] {
        guard let cat = selectedCategory else { return insights.insights }
        return insights.insights.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SFC.Spacing.lg) {
                    if let prediction = analytics.pacePrediction {
                        predictionCard(prediction)
                    }
                    categoryFilter
                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "Nessun insight",
                            systemImage: "sparkles",
                            description: Text("Completa più allenamenti per generare analisi AI.")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(filtered) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding(SFC.Spacing.md)
            }
            .background(SFC.Color.deepBlack.ignoresSafeArea())
            .navigationTitle("AI Insights")
        }
    }

    private func predictionCard(_ prediction: PacePrediction) -> some View {
        VStack(alignment: .leading, spacing: SFC.Spacing.sm) {
            Label("Previsione AI", systemImage: "sparkles")
                .font(SFC.Font.headline())
                .foregroundStyle(SFC.Color.electricBlue)

            let m = Int(prediction.predictedPaceSecPerKm) / 60
            let s = Int(prediction.predictedPaceSecPerKm) % 60
            Text("Ritmo previsto: \(m):\(String(format: "%02d", s))/km")
                .font(SFC.Font.metric(24))

            HStack {
                Text("Confidenza: \(String(format: "%.0f", prediction.confidence * 100))%")
                Spacer()
                Text("Basato su \(prediction.basedOnWorkouts) corse")
            }
            .font(SFC.Font.caption())
            .foregroundStyle(SFC.Color.textSecondary)
        }
        .padding(SFC.Spacing.md)
        .sfcCard(accent: SFC.Color.electricBlue)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SFC.Spacing.sm) {
                FilterChip(title: "Tutti", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(InsightCategory.allCases, id: \.rawValue) { cat in
                    FilterChip(title: cat.rawValue.capitalized, icon: cat.icon, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
        }
    }
}

struct InsightCard: View {
    let insight: AIInsight

    var body: some View {
        HStack(alignment: .top, spacing: SFC.Spacing.md) {
            Image(systemName: insight.category.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: insight.category.color))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(SFC.Font.headline(15))
                Text(insight.body)
                    .font(SFC.Font.body(13))
                    .foregroundStyle(SFC.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let sport = insight.relatedSport {
                    Text(sport.displayName)
                        .font(SFC.Font.caption(10))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: sport.accentColor).opacity(0.2))
                        .foregroundStyle(Color(hex: sport.accentColor))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(SFC.Spacing.md)
        .sfcCard(accent: Color(hex: insight.category.color))
    }
}