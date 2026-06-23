import Foundation

@MainActor
final class AnalyticsEngine: ObservableObject {
    @Published var performanceMetrics = PerformanceMetrics(
        vo2MaxEstimate: nil, trainingLoad: 0, sessionIntensity: 0,
        stressScore: 0, performanceScore: 0, trendDirection: .stable, weeklyChangePercent: nil
    )
    @Published var distanceTrend: [TrendPoint] = []
    @Published var paceTrend: [TrendPoint] = []
    @Published var powerTrend: [TrendPoint] = []
    @Published var heartRateTrend: [TrendPoint] = []
    @Published var caloriesTrend: [TrendPoint] = []
    @Published var heatmapData: [HeatmapCell] = []
    @Published var sportAnalyses: [SportAnalysis] = []
    @Published var pacePrediction: PacePrediction?

    func compute(from workouts: [WorkoutActivity]) {
        guard !workouts.isEmpty else { return }

        performanceMetrics = computePerformanceMetrics(workouts)
        distanceTrend = buildTrend(workouts, value: \.distanceKm)
        paceTrend = buildTrend(workouts.filter { $0.avgPaceSecPerKm != nil }, value: \.avgPaceSecPerKm)
        powerTrend = buildTrend(workouts.filter { $0.avgPower != nil }, value: \.avgPower)
        heartRateTrend = buildTrend(workouts.filter { $0.avgHeartRate != nil }, value: \.avgHeartRate)
        caloriesTrend = buildTrend(workouts, value: \.activeCalories)
        heatmapData = buildHeatmap(workouts)
        sportAnalyses = SportType.allCases.compactMap { sport in
            analyzeSport(sport, workouts: workouts.filter { $0.sport == sport })
        }
        pacePrediction = predictPace(from: workouts)
    }

    func compareWorkouts(_ a: WorkoutActivity, _ b: WorkoutActivity) -> ComparisonResult {
        ComparisonResult(
            title: "Confronto attività",
            periodA: a.startDate.formatted(date: .abbreviated, time: .omitted),
            periodB: b.startDate.formatted(date: .abbreviated, time: .omitted),
            metrics: [
                ComparisonMetric(name: "Distanza", valueA: a.distanceKm ?? 0, valueB: b.distanceKm ?? 0, unit: "km", lowerIsBetter: false),
                ComparisonMetric(name: "Durata", valueA: a.duration / 60, valueB: b.duration / 60, unit: "min", lowerIsBetter: false),
                ComparisonMetric(name: "Ritmo", valueA: a.avgPaceSecPerKm ?? 0, valueB: b.avgPaceSecPerKm ?? 0, unit: "s/km", lowerIsBetter: true),
                ComparisonMetric(name: "FC media", valueA: a.avgHeartRate ?? 0, valueB: b.avgHeartRate ?? 0, unit: "bpm", lowerIsBetter: true),
                ComparisonMetric(name: "Potenza", valueA: a.avgPower ?? 0, valueB: b.avgPower ?? 0, unit: "W", lowerIsBetter: false),
                ComparisonMetric(name: "Calorie", valueA: a.activeCalories ?? 0, valueB: b.activeCalories ?? 0, unit: "kcal", lowerIsBetter: false),
            ]
        )
    }

    func comparePeriods(
        _ periodA: TimePeriod, _ periodB: TimePeriod,
        workouts: [WorkoutActivity], reference: Date = Date()
    ) -> ComparisonResult {
        let cal = Calendar.current
        let rangeA = periodDateRange(periodA, reference: reference, offset: 0, cal: cal)
        let rangeB = periodDateRange(periodB, reference: reference, offset: -1, cal: cal)

        let wA = workouts.filter { $0.startDate >= rangeA.start && $0.startDate <= rangeA.end }
        let wB = workouts.filter { $0.startDate >= rangeB.start && $0.startDate <= rangeB.end }

        func avg(_ ws: [WorkoutActivity], _ key: (WorkoutActivity) -> Double?) -> Double {
            let vals = ws.compactMap(key)
            return vals.isEmpty ? 0 : vals.reduce(0, +) / Double(vals.count)
        }

        return ComparisonResult(
            title: "\(periodA.label) vs precedente",
            periodA: periodA.label,
            periodB: "Precedente",
            metrics: [
                ComparisonMetric(name: "Distanza totale", valueA: wA.compactMap(\.distanceKm).reduce(0, +), valueB: wB.compactMap(\.distanceKm).reduce(0, +), unit: "km", lowerIsBetter: false),
                ComparisonMetric(name: "Workout", valueA: Double(wA.count), valueB: Double(wB.count), unit: "", lowerIsBetter: false),
                ComparisonMetric(name: "Ritmo medio", valueA: avg(wA, \.avgPaceSecPerKm), valueB: avg(wB, \.avgPaceSecPerKm), unit: "s/km", lowerIsBetter: true),
                ComparisonMetric(name: "FC media", valueA: avg(wA, \.avgHeartRate), valueB: avg(wB, \.avgHeartRate), unit: "bpm", lowerIsBetter: true),
                ComparisonMetric(name: "Calorie", valueA: wA.compactMap(\.activeCalories).reduce(0, +), valueB: wB.compactMap(\.activeCalories).reduce(0, +), unit: "kcal", lowerIsBetter: false),
            ]
        )
    }

    private func computePerformanceMetrics(_ workouts: [WorkoutActivity]) -> PerformanceMetrics {
        let recent = workouts.prefix(30)
        let trainingLoad = recent.map { ($0.duration / 3600) * ( $0.avgHeartRate ?? 120) / 100 }.reduce(0, +)
        let intensity = recent.compactMap(\.avgHeartRate).reduce(0, +) / Double(max(recent.count, 1)) / 190 * 100
        let stress = min(100, trainingLoad / 10)
        let score = min(100, (recent.compactMap(\.distanceKm).reduce(0, +) * 2) + (100 - stress) * 0.3)
        let vo2 = recent.compactMap(\.vo2MaxEstimate).max()

        let weeklyChange = computeWeeklyChange(workouts)
        let trend: TrendDirection
        if let change = weeklyChange {
            trend = change > 2 ? .improving : (change < -2 ? .declining : .stable)
        } else {
            trend = .stable
        }

        return PerformanceMetrics(
            vo2MaxEstimate: vo2,
            trainingLoad: trainingLoad,
            sessionIntensity: intensity,
            stressScore: stress,
            performanceScore: score,
            trendDirection: trend,
            weeklyChangePercent: weeklyChange
        )
    }

    private func computeWeeklyChange(_ workouts: [WorkoutActivity]) -> Double? {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let prevStart = cal.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { return nil }

        let thisWeek = workouts.filter { $0.startDate >= weekStart }.compactMap(\.distanceKm).reduce(0, +)
        let lastWeek = workouts.filter { $0.startDate >= prevStart && $0.startDate < weekStart }.compactMap(\.distanceKm).reduce(0, +)
        guard lastWeek > 0 else { return nil }
        return ((thisWeek - lastWeek) / lastWeek) * 100
    }

    private func buildTrend<T>(_ workouts: [WorkoutActivity], value: (WorkoutActivity) -> T?) -> [TrendPoint] where T: BinaryFloatingPoint {
        workouts.suffix(60).map { w in
            TrendPoint(date: w.startDate, value: Double(value(w) ?? 0), label: w.sport.displayName)
        }.sorted { $0.date < $1.date }
    }

    private func buildHeatmap(_ workouts: [WorkoutActivity]) -> [HeatmapCell] {
        let cal = Calendar.current
        var cells: [HeatmapCell] = []
        for weekOffset in 0..<12 {
            for day in 0..<7 {
                guard let date = cal.date(byAdding: .day, value: -(weekOffset * 7 + (6 - day)), to: Date()) else { continue }
                let dayStart = cal.startOfDay(for: date)
                let dist = workouts.filter { cal.isDate($0.startDate, inSameDayAs: dayStart) }
                    .compactMap(\.distanceKm).reduce(0, +)
                cells.append(HeatmapCell(day: day, week: weekOffset, value: dist, date: dayStart))
            }
        }
        return cells
    }

    private func analyzeSport(_ sport: SportType, workouts: [WorkoutActivity]) -> SportAnalysis? {
        guard !workouts.isEmpty else { return nil }
        let dist = workouts.compactMap(\.distanceKm).reduce(0, +)
        let paces = workouts.compactMap(\.avgPaceSecPerKm)
        let powers = workouts.compactMap(\.avgPower)
        let hrs = workouts.compactMap(\.avgHeartRate)

        var splits: [SplitData] = []
        if let last = workouts.first, let km = last.distanceKm, km > 1 {
            let pace = last.avgPaceSecPerKm ?? 0
            for i in 1...Int(km) {
                splits.append(SplitData(index: i, distanceKm: 1, paceSecPerKm: pace + Double.random(in: -15...15), heartRate: last.avgHeartRate, elevation: nil))
            }
        }

        let allZones = workouts.flatMap(\.heartRateZones)
        let zoneMap = Dictionary(grouping: allZones, by: \.zone)
        let zones = zoneMap.map { zone, data in
            HeartRateZoneData(
                zone: zone, name: data.first?.name ?? "Z\(zone)",
                minutes: data.map(\.minutes).reduce(0, +),
                percentage: data.map(\.percentage).reduce(0, +) / Double(data.count),
                colorHex: data.first?.colorHex ?? "007AFF"
            )
        }.sorted { $0.zone < $1.zone }

        return SportAnalysis(
            sport: sport, period: .monthly,
            totalWorkouts: workouts.count, totalDistanceKm: dist,
            avgPace: paces.isEmpty ? nil : paces.reduce(0, +) / Double(paces.count),
            avgPower: powers.isEmpty ? nil : powers.reduce(0, +) / Double(powers.count),
            avgHeartRate: hrs.isEmpty ? nil : hrs.reduce(0, +) / Double(hrs.count),
            avgElevation: workouts.compactMap(\.elevationGain).reduce(0, +) / Double(workouts.count),
            pacePerKmSplits: splits,
            powerTrend: buildTrend(workouts, value: \.avgPower),
            heartRateTrend: buildTrend(workouts, value: \.avgHeartRate),
            zoneDistribution: zones,
            cadenceAvg: workouts.compactMap(\.cadence).first,
            swimPacePer100m: workouts.compactMap(\.swimPacePer100m).first
        )
    }

    private func predictPace(from workouts: [WorkoutActivity]) -> PacePrediction? {
        let runs = workouts.filter { $0.sport == .outdoorRun || $0.sport == .indoorRun }
            .compactMap(\.avgPaceSecPerKm)
        guard runs.count >= 3 else { return nil }

        let recent = Array(runs.prefix(10))
        let slope = linearRegression(recent)
        let predicted = max(recent.last! + slope * -5, recent.min()! * 0.95)

        return PacePrediction(
            predictedPaceSecPerKm: predicted,
            predictedVO2Max: performanceMetrics.vo2MaxEstimate.map { $0 + slope * -0.1 },
            confidence: min(0.95, Double(recent.count) / 20),
            basedOnWorkouts: recent.count
        )
    }

    private func linearRegression(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let n = Double(values.count)
        let xs = (0..<values.count).map(Double.init)
        let sumX = xs.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xs, values).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return 0 }
        return (n * sumXY - sumX * sumY) / denom
    }

    private func periodDateRange(_ period: TimePeriod, reference: Date, offset: Int, cal: Calendar) -> (start: Date, end: Date) {
        switch period {
        case .weekly:
            let start = cal.date(byAdding: .weekOfYear, value: offset, to: cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference))!)!
            let end = cal.date(byAdding: .day, value: 6, to: start)!
            return (start, end)
        case .monthly:
            let start = cal.date(byAdding: .month, value: offset, to: cal.date(from: cal.dateComponents([.year, .month], from: reference))!)!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, cal.date(byAdding: .day, value: -1, to: end)!)
        case .yearly:
            let start = cal.date(byAdding: .year, value: offset, to: cal.date(from: cal.dateComponents([.year], from: reference))!)!
            let end = cal.date(byAdding: .year, value: 1, to: start)!
            return (start, cal.date(byAdding: .day, value: -1, to: end)!)
        case .daily:
            let start = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: reference))!
            return (start, cal.date(byAdding: .day, value: 1, to: start)!)
        }
    }
}