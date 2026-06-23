import Foundation
import HealthKit

enum SportType: String, CaseIterable, Codable, Identifiable {
    case outdoorRun = "outdoor_run"
    case indoorRun = "indoor_run"
    case outdoorCycling = "outdoor_cycling"
    case indoorCycling = "indoor_cycling"
    case swimming = "swimming"
    case walking = "walking"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .outdoorRun: return "Corsa Outdoor"
        case .indoorRun: return "Corsa Indoor"
        case .outdoorCycling: return "Bici Outdoor"
        case .indoorCycling: return "Bici Indoor"
        case .swimming: return "Nuoto"
        case .walking: return "Camminata"
        case .other: return "Altro"
        }
    }

    var icon: String {
        switch self {
        case .outdoorRun, .indoorRun: return "figure.run"
        case .outdoorCycling, .indoorCycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .other: return "figure.mixed.cardio"
        }
    }

    var accentColor: String {
        switch self {
        case .outdoorRun, .indoorRun: return "007AFF"
        case .outdoorCycling, .indoorCycling: return "FF7A00"
        case .swimming: return "00FF7F"
        case .walking: return "5AC8FA"
        case .other: return "8E8E93"
        }
    }

    static func from(_ workout: HKWorkout) -> SportType {
        switch workout.workoutActivityType {
        case .running:
            return workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true ? .indoorRun : .outdoorRun
        case .cycling:
            return workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true ? .indoorCycling : .outdoorCycling
        case .swimming: return .swimming
        case .walking, .hiking: return .walking
        @unknown default: return .other
        }
    }
}

struct WorkoutActivity: Identifiable, Codable, Hashable {
    let id: UUID
    let sport: SportType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let distanceMeters: Double?
    let activeCalories: Double?
    let totalCalories: Double?
    let avgHeartRate: Double?
    let maxHeartRate: Double?
    let minHeartRate: Double?
    let avgPower: Double?
    let maxPower: Double?
    let elevationGain: Double?
    let avgPaceSecPerKm: Double?
    let avgSpeedKmh: Double?
    let steps: Int?
    let vo2MaxEstimate: Double?
    let swimStyle: String?
    let swimLaps: Int?
    let swimPacePer100m: Double?
    let cadence: Double?
    let heartRateZones: [HeartRateZoneData]
    let sourceName: String?

    var distanceKm: Double? {
        distanceMeters.map { $0 / 1000 }
    }

    var durationFormatted: String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        let s = Int(duration) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    var paceFormatted: String? {
        guard let pace = avgPaceSecPerKm else { return nil }
        let m = Int(pace) / 60
        let s = Int(pace) % 60
        return String(format: "%d:%02d /km", m, s)
    }
}

struct HeartRateZoneData: Codable, Hashable, Identifiable {
    let zone: Int
    let name: String
    let minutes: Double
    let percentage: Double
    let colorHex: String

    var id: Int { zone }
}

struct DailySummary: Identifiable, Codable {
    let date: Date
    let totalDistanceKm: Double
    let totalDuration: TimeInterval
    let totalCalories: Double
    let totalSteps: Int
    let workoutCount: Int
    let avgHeartRate: Double?
    let performanceScore: Double

    var id: Date { date }
}

enum TimePeriod: String, CaseIterable, Identifiable, Codable {
    case daily, weekly, monthly, yearly
    var id: String { rawValue }
    var label: String {
        switch self {
        case .daily: return "Giorno"
        case .weekly: return "Settimana"
        case .monthly: return "Mese"
        case .yearly: return "Anno"
        }
    }
}