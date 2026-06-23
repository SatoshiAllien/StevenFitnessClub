import Foundation

@MainActor
final class InsightsEngine: ObservableObject {
    @Published var insights: [AIInsight] = []

    func generate(workouts: [WorkoutActivity], metrics: PerformanceMetrics) {
        var results: [AIInsight] = []
        let now = Date()

        if let change = metrics.weeklyChangePercent {
            if change > 5 {
                results.append(AIInsight(
                    id: UUID(), category: .improvement,
                    title: "Volume in crescita",
                    body: "Hai aumentato il volume del \(String(format: "%.0f", change))% questa settimana. Ottimo lavoro di costruzione della base aerobica.",
                    priority: 1, relatedSport: nil, createdAt: now
                ))
            } else if change < -15 {
                results.append(AIInsight(
                    id: UUID(), category: .recovery,
                    title: "Volume in calo",
                    body: "Il volume settimanale è sceso del \(String(format: "%.0f", abs(change)))%. Valuta se serve più recupero o ripianifica gli allenamenti.",
                    priority: 2, relatedSport: nil, createdAt: now
                ))
            }
        }

        if metrics.stressScore > 70 {
            results.append(AIInsight(
                id: UUID(), category: .recovery,
                title: "Stress elevato",
                body: "Il tuo stress score è \(String(format: "%.0f", metrics.stressScore))/100. Considera una giornata di recupero attivo o riposo completo.",
                priority: 1, relatedSport: nil, createdAt: now
            ))
        }

        if let vo2 = metrics.vo2MaxEstimate {
            results.append(AIInsight(
                id: UUID(), category: .prediction,
                title: "VO₂ max stimato: \(String(format: "%.1f", vo2)) ml/kg/min",
                body: vo2 > 50
                    ? "Il tuo livello cardio è eccellente. Mantieni 1-2 sessioni di qualità a settimana."
                    : "Per migliorare il VO₂, aggiungi 2 sessioni di interval training a settimana (4×4 min Z4).",
                priority: 2, relatedSport: .outdoorRun, createdAt: now
            ))
        }

        for sport in SportType.allCases {
            let sportWorkouts = workouts.filter { $0.sport == sport }
            guard sportWorkouts.count >= 3 else { continue }

            if let weakness = findWeakness(sport: sport, workouts: sportWorkouts) {
                results.append(weakness)
            }
        }

        if let training = generateTrainingSuggestion(workouts: workouts) {
            results.append(training)
        }

        if let prediction = generatePacePrediction(workouts: workouts) {
            results.append(prediction)
        }

        insights = results.sorted { $0.priority < $1.priority }
    }

    private func findWeakness(sport: SportType, workouts: [WorkoutActivity]) -> AIInsight? {
        let zones = workouts.flatMap(\.heartRateZones)
        let z4z5 = zones.filter { $0.zone >= 4 }.map(\.percentage).reduce(0, +)
        let z1z2 = zones.filter { $0.zone <= 2 }.map(\.percentage).reduce(0, +)

        if z4z5 > 40 {
            return AIInsight(
                id: UUID(), category: .weakness,
                title: "Troppe sessioni ad alta intensità — \(sport.displayName)",
                body: "Il \(String(format: "%.0f", z4z5))% del tempo è in Z4-Z5. Bilancia con più volume in Z2 per migliorare la resistenza aerobica.",
                priority: 2, relatedSport: sport, createdAt: Date()
            )
        }

        if z1z2 > 80 && workouts.count > 5 {
            return AIInsight(
                id: UUID(), category: .training,
                title: "Aggiungi intensità — \(sport.displayName)",
                body: "L'80%+ del tempo è in zona facile. Inserisci 1 sessione di soglia/settimana per rompere il plateau.",
                priority: 3, relatedSport: sport, createdAt: Date()
            )
        }

        return nil
    }

    private func generateTrainingSuggestion(workouts: [WorkoutActivity]) -> AIInsight? {
        let last7 = workouts.filter { $0.startDate > Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
        guard last7.count < 3 else { return nil }

        return AIInsight(
            id: UUID(), category: .training,
            title: "Aumenta la frequenza",
            body: "Solo \(last7.count) allenamenti negli ultimi 7 giorni. Punta a 3-4 sessioni per progressi costanti.",
            priority: 2, relatedSport: nil, createdAt: Date()
        )
    }

    private func generatePacePrediction(workouts: [WorkoutActivity]) -> AIInsight? {
        let runs = workouts.filter { $0.sport == .outdoorRun || $0.sport == .indoorRun }
        let paces = runs.prefix(10).compactMap(\.avgPaceSecPerKm)
        guard paces.count >= 5 else { return nil }

        let trend = paces.first! - paces.last!
        if trend > 10 {
            let future = paces.first! - (trend / Double(paces.count)) * 4
            let m = Int(future) / 60; let s = Int(future) % 60
            return AIInsight(
                id: UUID(), category: .prediction,
                title: "Previsione ritmo tra 4 settimane",
                body: "Basandosi sul trend attuale, il tuo ritmo medio potrebbe scendere a \(m):\(String(format: "%02d", s))/km.",
                priority: 3, relatedSport: .outdoorRun, createdAt: Date()
            )
        }
        return nil
    }
}