import SwiftUI
import Charts

struct DistanceTrendChart: View {
    let data: [TrendPoint]
    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Data", point.date),
                y: .value("Km", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [SFC.Color.electricBlue.opacity(0.4), SFC.Color.electricBlue.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Data", point.date),
                y: .value("Km", point.value)
            )
            .foregroundStyle(SFC.Color.electricBlue)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(SFC.Color.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(SFC.Color.cardBorder)
                AxisValueLabel()
                    .foregroundStyle(SFC.Color.textTertiary)
            }
        }
    }
}

struct PaceTrendChart: View {
    let data: [TrendPoint]
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Data", point.date),
                y: .value("Ritmo", point.value / 60)
            )
            .foregroundStyle(SFC.Color.performanceGreen)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            PointMark(
                x: .value("Data", point.date),
                y: .value("Ritmo", point.value / 60)
            )
            .foregroundStyle(SFC.Color.performanceGreen)
            .symbolSize(20)
        }
        .chartYAxisLabel("min/km")
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(SFC.Color.textTertiary)
            }
        }
    }
}

struct PowerTrendChart: View {
    let data: [TrendPoint]
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Data", point.date, unit: .day),
                y: .value("Watt", point.value)
            )
            .foregroundStyle(SFC.Color.energyOrange.gradient)
            .cornerRadius(4)
        }
        .chartYAxisLabel("Watt")
    }
}

struct HeartRateTrendChart: View {
    let data: [TrendPoint]
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Data", point.date),
                y: .value("BPM", point.value)
            )
            .foregroundStyle(
                LinearGradient(colors: [SFC.Color.zone4, SFC.Color.zone5], startPoint: .leading, endPoint: .trailing)
            )
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYAxisLabel("bpm")
    }
}

struct CaloriesBarChart: View {
    let data: [TrendPoint]
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Data", point.date, unit: .day),
                y: .value("Kcal", point.value)
            )
            .foregroundStyle(SFC.Color.energyOrange.opacity(0.8))
            .cornerRadius(3)
        }
    }
}

struct HeartRateZonePieChart: View {
    let zones: [HeartRateZoneData]
    var body: some View {
        Chart(zones) { zone in
            SectorMark(
                angle: .value("Minuti", zone.minutes),
                innerRadius: .ratio(0.55),
                angularInset: 2
            )
            .foregroundStyle(Color(hex: zone.colorHex))
            .cornerRadius(4)
        }
    }
}

struct WeeklyHeatmapChart: View {
    let cells: [HeatmapCell]

    var body: some View {
        let maxVal = cells.map(\.value).max() ?? 1
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(cells.sorted(by: { $0.week > $1.week || ($0.week == $1.week && $0.day < $1.day) })) { cell in
                RoundedRectangle(cornerRadius: 4)
                    .fill(SFC.Color.electricBlue.opacity(cell.value / max(maxVal, 0.01)))
                    .frame(height: 28)
                    .overlay {
                        if cell.value > 0 {
                            Text(String(format: "%.0f", cell.value))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
            }
        }
    }
}

struct SplitPaceChart: View {
    let splits: [SplitData]
    var body: some View {
        Chart(splits) { split in
            BarMark(
                x: .value("Km", "Km \(split.index)"),
                y: .value("Ritmo", split.paceSecPerKm / 60)
            )
            .foregroundStyle(
                split.paceSecPerKm < (splits.map(\.paceSecPerKm).reduce(0,+)/Double(splits.count))
                ? SFC.Color.performanceGreen.gradient
                : SFC.Color.energyOrange.gradient
            )
            .cornerRadius(4)
        }
        .chartYAxisLabel("min/km")
    }
}