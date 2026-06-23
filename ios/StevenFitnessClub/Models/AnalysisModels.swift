import Foundation

struct PerformanceMetrics: Codable {
    let vo2MaxEstimate: Double?
    let trainingLoad: Double
    let sessionIntensity: Double
    let stressScore: Double
    let performanceScore: Double
    let trendDirection: TrendDirection
    let weeklyChangePercent: Double?
}

enum TrendDirection: String, Codable {
    case improving, stable, declining

    var label: String {
        switch self {
        case .improving: return "In miglioramento"
        case .stable: return "Stabile"
        case .declining: return "In calo"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

struct TrendPoint: Identifiable, Codable {
    let date: Date
    let value: Double
    let label: String?

    var id: Date { date }
}

struct SportAnalysis: Identifiable, Codable {
    let sport: SportType
    let period: TimePeriod
    let totalWorkouts: Int
    let totalDistanceKm: Double
    let avgPace: Double?
    let avgPower: Double?
    let avgHeartRate: Double?
    let avgElevation: Double?
    let pacePerKmSplits: [SplitData]
    let powerTrend: [TrendPoint]
    let heartRateTrend: [TrendPoint]
    let zoneDistribution: [HeartRateZoneData]
    let cadenceAvg: Double?
    let swimPacePer100m: Double?

    var id: String { "\(sport.rawValue)-\(period.rawValue)" }
}

struct SplitData: Identifiable, Codable {
    let index: Int
    let distanceKm: Double
    let paceSecPerKm: Double
    let heartRate: Double?
    let elevation: Double?

    var id: Int { index }

    var paceFormatted: String {
        let m = Int(paceSecPerKm) / 60
        let s = Int(paceSecPerKm) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct ComparisonResult: Identifiable {
    let id = UUID()
    let title: String
    let periodA: String
    let periodB: String
    let metrics: [ComparisonMetric]
}

struct ComparisonMetric: Identifiable {
    let id = UUID()
    let name: String
    let valueA: Double
    let valueB: Double
    let unit: String
    let lowerIsBetter: Bool

    var delta: Double { valueB - valueA }
    var deltaPercent: Double {
        guard valueA != 0 else { return 0 }
        return (delta / valueA) * 100
    }

    var isImprovement: Bool {
        lowerIsBetter ? delta < 0 : delta > 0
    }
}

struct AIInsight: Identifiable, Codable {
    let id: UUID
    let category: InsightCategory
    let title: String
    let body: String
    let priority: Int
    let relatedSport: SportType?
    let createdAt: Date
}

enum InsightCategory: String, Codable, CaseIterable {
    case improvement, weakness, training, prediction, recovery

    var icon: String {
        switch self {
        case .improvement: return "chart.line.uptrend.xyaxis"
        case .weakness: return "exclamationmark.triangle"
        case .training: return "figure.run"
        case .prediction: return "sparkles"
        case .recovery: return "bed.double"
        }
    }

    var color: String {
        switch self {
        case .improvement: return "00FF7F"
        case .weakness: return "FF7A00"
        case .training: return "007AFF"
        case .prediction: return "BF5AF2"
        case .recovery: return "5AC8FA"
        }
    }
}

struct HeatmapCell: Identifiable {
    let id = UUID()
    let day: Int
    let week: Int
    let value: Double
    let date: Date?
}

struct PacePrediction: Codable {
    let predictedPaceSecPerKm: Double
    let predictedVO2Max: Double?
    let confidence: Double
    let basedOnWorkouts: Int
}