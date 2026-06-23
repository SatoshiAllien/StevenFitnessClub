import SwiftUI
import Charts

struct ActivityDetailView: View {
    let workout: WorkoutActivity

    var body: some View {
        ScrollView {
            VStack(spacing: SFC.Spacing.lg) {
                header
                metricsGrid
                sportSpecificSection
                if !workout.heartRateZones.isEmpty {
                    zonesSection
                }
            }
            .padding(SFC.Spacing.md)
        }
        .background(SFC.Color.deepBlack.ignoresSafeArea())
        .navigationTitle(workout.sport.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: SFC.Spacing.sm) {
            Image(systemName: workout.sport.icon)
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: workout.sport.accentColor))
            Text(workout.startDate.formatted(date: .complete, time: .shortened))
                .font(SFC.Font.caption())
                .foregroundStyle(SFC.Color.textSecondary)
            Text(workout.durationFormatted)
                .font(SFC.Font.metric(36))
        }
        .frame(maxWidth: .infinity)
        .padding(SFC.Spacing.lg)
        .sfcCard(accent: Color(hex: workout.sport.accentColor))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: SFC.Spacing.md) {
            detailMetric("Distanza", value: workout.distanceKm.map { String(format: "%.2f km", $0) } ?? "—")
            detailMetric("Ritmo", value: workout.paceFormatted ?? "—")
            detailMetric("Calorie", value: workout.activeCalories.map { String(format: "%.0f", $0) } ?? "—")
            detailMetric("FC media", value: workout.avgHeartRate.map { String(format: "%.0f bpm", $0) } ?? "—")
            detailMetric("FC max", value: workout.maxHeartRate.map { String(format: "%.0f bpm", $0) } ?? "—")
            detailMetric("Potenza", value: workout.avgPower.map { String(format: "%.0f W", $0) } ?? "—")
            detailMetric("Elevazione", value: workout.elevationGain.map { String(format: "%.0f m", $0) } ?? "—")
            detailMetric("Velocità", value: workout.avgSpeedKmh.map { String(format: "%.1f km/h", $0) } ?? "—")
            detailMetric("VO₂ st.", value: workout.vo2MaxEstimate.map { String(format: "%.1f", $0) } ?? "—")
        }
    }

    @ViewBuilder
    private var sportSpecificSection: some View {
        switch workout.sport {
        case .outdoorRun, .indoorRun:
            runSection
        case .outdoorCycling, .indoorCycling:
            cyclingSection
        case .swimming:
            swimSection
        case .walking:
            walkSection
        case .other:
            EmptyView()
        }
    }

    private var runSection: some View {
        chartCard("Ritmo") {
            if let pace = workout.paceFormatted {
                Text(pace)
                    .font(SFC.Font.metric(28))
                    .foregroundStyle(SFC.Color.performanceGreen)
            } else {
                Text("Dati split per km non disponibili da Apple Salute per questa attività.")
                    .font(SFC.Font.caption())
                    .foregroundStyle(SFC.Color.textTertiary)
            }
        }
    }

    private var cyclingSection: some View {
        VStack(spacing: SFC.Spacing.md) {
            chartCard("Potenza") {
                if let power = workout.avgPower {
                    Text("\(String(format: "%.0f", power)) W medi")
                        .font(SFC.Font.metric(28))
                        .foregroundStyle(SFC.Color.energyOrange)
                }
            }
            if let cadence = workout.cadence {
                chartCard("Cadenza") {
                    Text("\(String(format: "%.0f", cadence)) rpm")
                        .font(SFC.Font.metric(28))
                }
            }
        }
    }

    private var swimSection: some View {
        VStack(spacing: SFC.Spacing.md) {
            chartCard("Nuoto") {
                VStack(alignment: .leading, spacing: 8) {
                    if let style = workout.swimStyle {
                        Label("Stile: \(style)", systemImage: "figure.pool.swim")
                    }
                    if let laps = workout.swimLaps {
                        Label("Vasche: \(laps)", systemImage: "repeat")
                    }
                    if let pace = workout.swimPacePer100m {
                        let m = Int(pace) / 60; let s = Int(pace) % 60
                        Label("Ritmo: \(m):\(String(format: "%02d", s))/100m", systemImage: "timer")
                    }
                }
                .font(SFC.Font.body())
            }
        }
    }

    private var walkSection: some View {
        chartCard("Camminata") {
            VStack(alignment: .leading, spacing: 8) {
                if let steps = workout.steps {
                    Label("\(steps) passi", systemImage: "shoeprints.fill")
                }
                if let km = workout.distanceKm {
                    Label(String(format: "%.2f km", km), systemImage: "map")
                }
            }
            .font(SFC.Font.body())
        }
    }

    private var zonesSection: some View {
        chartCard("Zone cardio") {
            HStack(spacing: SFC.Spacing.lg) {
                HeartRateZonePieChart(zones: workout.heartRateZones)
                    .frame(width: 140, height: 140)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(workout.heartRateZones) { zone in
                        HStack {
                            Circle().fill(Color(hex: zone.colorHex)).frame(width: 8, height: 8)
                            Text(zone.name).font(SFC.Font.caption(11))
                            Spacer()
                            Text(String(format: "%.0f%%", zone.percentage))
                                .font(SFC.Font.caption(11))
                                .foregroundStyle(SFC.Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func detailMetric(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(SFC.Font.headline(13))
            Text(title).font(SFC.Font.caption(10)).foregroundStyle(SFC.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(SFC.Spacing.sm)
        .sfcCard()
    }

    private func chartCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SFC.Spacing.md) {
            Text(title).font(SFC.Font.headline())
            content()
        }
        .padding(SFC.Spacing.md)
        .sfcCard()
    }
}