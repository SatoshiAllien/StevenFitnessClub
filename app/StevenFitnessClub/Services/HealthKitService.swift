import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var lastSyncDate: Date?

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
            .activeEnergyBurned, .stepCount,
            .heartRate, .vo2Max,
            .runningSpeed, .runningPower, .cyclingPower,
            .flightsClimbed
        ]
        quantityIds.forEach { id in
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        types.insert(HKObjectType.workoutType())
        if let hrVar = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrVar)
        }
        return types
    }()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else {
            authorizationError = "HealthKit non disponibile su questo dispositivo."
            isAuthorized = false
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            // HealthKit non rivela se l'utente ha negato la lettura: verifichiamo con una query probe.
            isAuthorized = await probeReadAccess()
            if !isAuthorized {
                authorizationError = "Permessi Apple Salute non concessi. Vai in Impostazioni → Salute → Accesso dati → StevenFitnessClub e attiva tutti i dati."
            } else {
                authorizationError = nil
            }
        } catch {
            isAuthorized = false
            authorizationError = error.localizedDescription
        }
    }

    /// Tenta una lettura minima per capire se i permessi di lettura sono effettivi.
    private func probeReadAccess() async -> Bool {
        do {
            _ = try await fetchWorkouts(since: Calendar.current.date(byAdding: .day, value: -7, to: Date()))
            return true
        } catch {
            return false
        }
    }

    func fetchWorkouts(since startDate: Date? = nil) async throws -> [HKWorkout] {
        let predicate: NSPredicate?
        if let start = startDate ?? Calendar.current.date(byAdding: .year, value: -2, to: Date()) {
            predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        } else {
            predicate = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }

    func fetchHeartRateSamples(for workout: HKWorkout) async throws -> [(Date, Double)] {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate, end: workout.endDate, options: .strictStartDate
        )
        return try await fetchQuantitySamples(type: hrType, predicate: predicate, unit: .count().unitDivided(by: .minute()))
    }

    func fetchPowerSamples(for workout: HKWorkout) async throws -> [(Date, Double)] {
        let powerId: HKQuantityTypeIdentifier = {
            switch workout.workoutActivityType {
            case .running: return .runningPower
            default: return .cyclingPower
            }
        }()
        guard let type = HKQuantityType.quantityType(forIdentifier: powerId) else { return [] }
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate, end: workout.endDate, options: .strictStartDate
        )
        return try await fetchQuantitySamples(type: type, predicate: predicate, unit: .watt())
    }

    func fetchStepCount(for workout: HKWorkout) async throws -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate, end: workout.endDate, options: .strictStartDate
        )
        let samples = try await fetchQuantitySamples(type: stepType, predicate: predicate, unit: .count())
        let total = samples.map(\.1).reduce(0, +)
        return total > 0 ? Int(total) : nil
    }

    func fetchDailySteps(days: Int = 90) async throws -> [(Date, Double)] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return try await fetchQuantitySamples(type: stepType, predicate: predicate, unit: .count())
    }

    func fetchVO2Max() async throws -> Double? {
        guard let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return nil }
        let samples = try await fetchQuantitySamples(
            type: vo2Type,
            predicate: nil,
            unit: HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute())),
            limit: 1
        )
        return samples.first?.1
    }

    private func fetchQuantitySamples(
        type: HKQuantityType,
        predicate: NSPredicate?,
        unit: HKUnit,
        limit: Int = HKObjectQueryNoLimit
    ) async throws -> [(Date, Double)] {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sort]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let results = (samples as? [HKQuantitySample])?.map {
                    ($0.startDate, $0.quantity.doubleValue(for: unit))
                } ?? []
                continuation.resume(returning: results)
            }
            store.execute(query)
        }
    }
}