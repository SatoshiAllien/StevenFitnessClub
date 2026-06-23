import Foundation
import HealthKit

@MainActor
final class WorkoutDataStore: ObservableObject {
    @Published var workouts: [WorkoutActivity] = []
    @Published var dailySummaries: [DailySummary] = []
    @Published var isSyncing = false
    @Published var syncError: String?

    private let cacheKey = "sfc_workouts_cache"
    private let maxHR = 190.0

    init() { loadCache() }

    func syncFromHealthKit(healthKit: HealthKitService) async {
        guard healthKit.isAuthorized else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let hkWorkouts = try await healthKit.fetchWorkouts()
            var activities: [WorkoutActivity] = []

            for hk in hkWorkouts {
                let hrSamples = try await healthKit.fetchHeartRateSamples(for: hk)
                let powerSamples = try await healthKit.fetchPowerSamples(for: hk)
                activities.append(mapWorkout(hk, hrSamples: hrSamples, powerSamples: powerSamples))
            }

            workouts = activities.sorted { $0.startDate > $1.startDate }
            dailySummaries = buildDailySummaries(from: workouts)
            saveCache()
            healthKit.lastSyncDate = Date()
        } catch {
            syncError = error.localizedDescription
        }
    }

    func workouts(for sport: SportType) -> [WorkoutActivity] {
        workouts.filter { $0.sport == sport }
    }

    func workouts(in period: TimePeriod, referenceDate: Date = Date()) -> [WorkoutActivity] {
        let range = dateRange(for: period, reference: referenceDate)
        return workouts.filter { $0.startDate >= range.start && $0.startDate <= range.end }
    }

    private func mapWorkout(
        _ hk: HKWorkout,
        hrSamples: [(Date, Double)],
        powerSamples: [(Date, Double)]
    ) -> WorkoutActivity {
        let sport = SportType.from(hk)
        let distance = hk.totalDistance?.doubleValue(for: .meter())
        let calories = hk.totalEnergyBurned?.doubleValue(for: .kilocalorie())

        let hrValues = hrSamples.map(\.1)
        let avgHR = hrValues.isEmpty ? nil : hrValues.reduce(0, +) / Double(hrValues.count)
        let maxHRVal = hrValues.max()
        let minHRVal = hrValues.min()

        let powerValues = powerSamples.map(\.1)
        let avgPower = powerValues.isEmpty ? nil : powerValues.reduce(0, +) / Double(powerValues.count)
        let maxPower = powerValues.max()

        var pace: Double?
        var speed: Double?
        if let d = distance, d > 0 {
            pace = hk.duration / (d / 1000)
            speed = (d / 1000) / (hk.duration / 3600)
        }

        let elevation: Double? = {
            if let qty = hk.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity {
                return qty.doubleValue(for: .meter())
            }
            return hk.metadata?[HKMetadataKeyElevationAscended] as? Double
        }()

        let zones = computeHeartRateZones(samples: hrSamples, maxHR: maxHR)

        var swimStyle: String?
        var swimLaps: Int?
        var swimPace: Double?
        if sport == .swimming, let d = distance, d > 0 {
            swimStyle = hk.swimmingStrokeStyle?.name
            swimLaps = hk.metadata?[HKMetadataKeyLapLength] as? Int
            swimPace = hk.duration / (d / 100)
        }

        return WorkoutActivity(
            id: hk.uuid,
            sport: sport,
            startDate: hk.startDate,
            endDate: hk.endDate,
            duration: hk.duration,
            distanceMeters: distance,
            activeCalories: calories,
            totalCalories: calories,
            avgHeartRate: avgHR,
            maxHeartRate: maxHRVal,
            minHeartRate: minHRVal,
            avgPower: avgPower,
            maxPower: maxPower,
            elevationGain: elevation,
            avgPaceSecPerKm: pace,
            avgSpeedKmh: speed,
            steps: nil,
            vo2MaxEstimate: estimateVO2(avgHR: avgHR, duration: hk.duration),
            swimStyle: swimStyle,
            swimLaps: swimLaps,
            swimPacePer100m: swimPace,
            cadence: nil,
            heartRateZones: zones,
            sourceName: hk.sourceRevision.source.name
        )
    }

    private func computeHeartRateZones(samples: [(Date, Double)], maxHR: Double) -> [HeartRateZoneData] {
        guard !samples.isEmpty else { return [] }
        let thresholds = [0.6, 0.7, 0.8, 0.9]
        let names = ["Z1 Recupero", "Z2 Aerobico", "Z3 Tempo", "Z4 Soglia", "Z5 Max"]
        let colors = ["5AC8FA", "34C759", "FFCC00", "FF9500", "FF3B30"]
        var zoneMinutes = Array(repeating: 0.0, count: 5)

        for (_, hr) in samples {
            let pct = hr / maxHR
            let zone: Int
            if pct < thresholds[0] { zone = 0 }
            else if pct < thresholds[1] { zone = 1 }
            else if pct < thresholds[2] { zone = 2 }
            else if pct < thresholds[3] { zone = 3 }
            else { zone = 4 }
            zoneMinutes[zone] += 1.0 / 60.0
        }

        let total = zoneMinutes.reduce(0, +)
        guard total > 0 else { return [] }

        return (0..<5).map { i in
            HeartRateZoneData(
                zone: i + 1,
                name: names[i],
                minutes: zoneMinutes[i],
                percentage: (zoneMinutes[i] / total) * 100,
                colorHex: colors[i]
            )
        }.filter { $0.minutes > 0 }
    }

    private func estimateVO2(avgHR: Double?, duration: TimeInterval) -> Double? {
        guard let hr = avgHR, duration > 600 else { return nil }
        return 15.3 * (220 - hr) / hr
    }

    private func buildDailySummaries(from workouts: [WorkoutActivity]) -> [DailySummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) {
            calendar.startOfDay(for: $0.startDate)
        }

        return grouped.map { date, dayWorkouts in
            DailySummary(
                date: date,
                totalDistanceKm: dayWorkouts.compactMap(\.distanceKm).reduce(0, +),
                totalDuration: dayWorkouts.map(\.duration).reduce(0, +),
                totalCalories: dayWorkouts.compactMap(\.activeCalories).reduce(0, +),
                totalSteps: dayWorkouts.compactMap(\.steps).reduce(0, +),
                workoutCount: dayWorkouts.count,
                avgHeartRate: {
                    let hrs = dayWorkouts.compactMap(\.avgHeartRate)
                    return hrs.isEmpty ? nil : hrs.reduce(0, +) / Double(hrs.count)
                }(),
                performanceScore: dayWorkouts.map { $0.distanceKm ?? 0 }.reduce(0, +) * 10
            )
        }.sorted { $0.date > $1.date }
    }

    private func dateRange(for period: TimePeriod, reference: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch period {
        case .daily:
            return (cal.startOfDay(for: reference), reference)
        case .weekly:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference))!
            return (start, reference)
        case .monthly:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: reference))!
            return (start, reference)
        case .yearly:
            let start = cal.date(from: cal.dateComponents([.year], from: reference))!
            return (start, reference)
        }
    }

    private func saveCache() {
        if let data = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode([WorkoutActivity].self, from: data) else { return }
        workouts = cached
        dailySummaries = buildDailySummaries(from: workouts)
    }
}

private extension HKWorkout {
    var swimmingStrokeStyle: HKSwimmingStrokeStyle? {
        if let raw = metadata?[HKMetadataKeySwimmingStrokeStyle] as? Int {
            return HKSwimmingStrokeStyle(rawValue: raw)
        }
        if let num = metadata?[HKMetadataKeySwimmingStrokeStyle] as? NSNumber {
            return HKSwimmingStrokeStyle(rawValue: num.intValue)
        }
        return nil
    }
}

private extension HKSwimmingStrokeStyle {
    var name: String {
        switch self {
        case .freestyle: return "Stile Libero"
        case .backstroke: return "Dorso"
        case .breaststroke: return "Rana"
        case .butterfly: return "Farfalla"
        case .mixed: return "Misto"
        case .kickboard: return "Kickboard"
        case .unknown: return "Sconosciuto"
        @unknown default: return "Altro"
        }
    }
}