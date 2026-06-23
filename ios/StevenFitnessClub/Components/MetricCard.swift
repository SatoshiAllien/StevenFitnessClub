import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let accent: Color
    var trend: String? = nil
    var trendUp: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: SFC.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer()
                if let trend {
                    HStack(spacing: 2) {
                        Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                        Text(trend)
                    }
                    .font(SFC.Font.caption(10))
                    .foregroundStyle(trendUp ? SFC.Color.performanceGreen : SFC.Color.energyOrange)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(SFC.Font.metric(26))
                    .foregroundStyle(SFC.Color.textPrimary)
                Text(unit)
                    .font(SFC.Font.caption())
                    .foregroundStyle(SFC.Color.textSecondary)
            }

            Text(title)
                .font(SFC.Font.caption())
                .foregroundStyle(SFC.Color.textTertiary)
        }
        .padding(SFC.Spacing.md)
        .sfcCard(accent: accent)
    }
}

struct PeriodPicker: View {
    @Binding var selection: TimePeriod

    var body: some View {
        HStack(spacing: SFC.Spacing.sm) {
            ForEach(TimePeriod.allCases) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) { selection = period }
                } label: {
                    Text(period.label)
                        .font(SFC.Font.caption(13))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selection == period ? SFC.Color.electricBlue : SFC.Color.cardBackground)
                        .foregroundStyle(selection == period ? .white : SFC.Color.textSecondary)
                        .clipShape(Capsule())
                }
            }
        }
    }
}